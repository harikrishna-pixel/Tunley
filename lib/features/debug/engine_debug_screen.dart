import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/config.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/rules/ringtone_rules.dart';
import '../../l10n/app_localizations.dart';

/// Temporary Phase 3 screen: pick → inspect → convert to every format → play / share / save.
class EngineDebugScreen extends ConsumerStatefulWidget {
  const EngineDebugScreen({super.key});

  @override
  ConsumerState<EngineDebugScreen> createState() => _EngineDebugScreenState();
}

class _EngineDebugScreenState extends ConsumerState<EngineDebugScreen> {
  final _player = AudioPlayer();
  StreamSubscription<ProgressEvent>? _progressSub;

  String? _source;
  MediaInfo? _info;
  List<double> _peaks = const [];
  String? _sourceError;
  Set<OutFormat> _available = const {};
  int? _freeBytes;
  final List<_Outcome> _outcomes = [];
  bool _busy = false;
  String? _jobId;
  double _progress = 0;
  String? _playing;
  String? _folderId;
  String? _savedMessage;

  AudioEngine get _engine => ref.read(audioEngineProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEngineState());
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadEngineState() async {
    final available = await _engine.availableFormats();
    final free = await _engine.freeBytes();
    if (!mounted) return;
    setState(() {
      _available = available;
      _freeBytes = free;
    });
  }

  Future<void> _pickVideo() async {
    try {
      final paths = await _engine.pickVideos();
      if (paths.isNotEmpty) await _load(paths.first);
    } on EngineException catch (error) {
      setState(() => _sourceError = error.code.name);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const [
        'mp3',
        'm4a',
        'wav',
        'aiff',
        'aif',
        'caf',
        'flac',
        'aac',
        'mp4',
        'mov',
      ],
    );
    final path = result?.path;
    if (path != null) await _load(path);
  }

  Future<void> _load(String path) async {
    setState(() {
      _source = path;
      _info = null;
      _peaks = const [];
      _sourceError = null;
      _outcomes.clear();
    });
    try {
      final info = await _engine.inspect(path);
      final peaks = info.hasAudio && !info.isProtected
          ? await _engine.waveform(path, buckets: 48)
          : const <double>[];
      if (!mounted) return;
      setState(() {
        _info = info;
        _peaks = peaks;
      });
    } on EngineException catch (error) {
      if (!mounted) return;
      setState(() => _sourceError = error.code.name);
    }
  }

  Future<void> _convertAll() async {
    final info = _info;
    final source = _source;
    if (info == null || source == null) return;
    final config = ref.read(appConfigProvider);
    final base = _baseName(source);
    setState(() {
      _busy = true;
      _outcomes.clear();
    });

    for (final format in OutFormat.values) {
      if (!mounted) return;
      if (!_available.contains(format)) {
        setState(() => _outcomes.add(_Outcome(format, unavailable: true)));
        continue;
      }
      final ringtone = format == OutFormat.m4r;
      final jobId = '${DateTime.now().microsecondsSinceEpoch}-${format.name}';
      final end = ringtone
          ? (info.durationSec < config.ringtoneMaxSeconds
                ? info.durationSec
                : config.ringtoneMaxSeconds.toDouble())
          : 0.0;
      final fade = ringtone ? config.fadeDefaultSeconds.toDouble() : 0.0;
      final request = ConvertRequest(
        inputs: [source],
        format: format,
        bitrateKbps: ringtone ? 128 : 256,
        startSec: 0,
        endSec: end,
        fadeInSec: fade,
        fadeOutSec: fade,
        gainDb: 0,
        crossfadeSec: 0,
        outputName: ringtone
            ? RingtoneRules.fileName(base).replaceAll(RegExp(r'\.m4r$'), '')
            : base,
      );

      _progressSub?.cancel();
      _progressSub = _engine.progress(jobId).listen((event) {
        if (mounted) setState(() => _progress = event.fraction);
      });
      setState(() {
        _jobId = jobId;
        _progress = 0;
      });
      try {
        final result = await _engine.convert(jobId, request);
        if (!mounted) return;
        setState(() => _outcomes.add(_Outcome(format, result: result)));
      } on EngineException catch (error) {
        if (!mounted) return;
        setState(() => _outcomes.add(_Outcome(format, error: error.code.name)));
        if (error.code == EngineErrorCode.cancelled) break;
      }
    }
    await _progressSub?.cancel();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _jobId = null;
    });
    unawaited(_loadEngineState());
  }

  Future<void> _togglePlay(String path) async {
    if (_playing == path) {
      await _player.stop();
      setState(() => _playing = null);
      return;
    }
    setState(() => _playing = path);
    await _player.setFilePath(path);
    unawaited(
      _player.play().whenComplete(() {
        if (mounted && _playing == path) setState(() => _playing = null);
      }),
    );
  }

  Future<void> _share(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  Future<void> _saveToFolder(String path) async {
    final l10n = AppLocalizations.of(context);
    try {
      var folder = _folderId;
      folder ??= await _engine.pickFolder();
      if (folder == null) return;
      final name = await _engine.copyToBookmarkedFolder(path, folder);
      final folderName = await _engine.bookmarkedFolderName(folder) ?? '';
      if (!mounted) return;
      setState(() {
        _folderId = folder;
        _savedMessage = l10n.engineSavedTo(folderName, name);
      });
    } on EngineException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.code == EngineErrorCode.staleBookmark) _folderId = null;
        _savedMessage = error.code.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final info = _info;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        elevation: 0,
        title: Text(l10n.engineDebugTitle, style: text.navTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.s24,
        ),
        children: [
          PrimaryButton(
            label: l10n.enginePickVideo,
            icon: PhosphorIcons.filmSlate(),
            onPressed: _busy ? null : _pickVideo,
          ),
          const SizedBox(height: AppSpace.s8),
          Row(
            children: [
              TextLinkButton(
                label: l10n.enginePickAudio,
                onPressed: _busy ? null : _pickAudio,
              ),
              const Spacer(),
              if (_freeBytes != null)
                Text(
                  l10n.engineFreeSpace(_formatBytes(_freeBytes!)),
                  style: text.caption,
                ),
            ],
          ),
          if (_sourceError != null) ...[
            const SizedBox(height: AppSpace.s12),
            StatusBox(message: _sourceError!, tone: StatusTone.danger),
          ],
          if (info != null) ...[
            const SizedBox(height: AppSpace.s16),
            Text(_baseName(info.path), style: text.title),
            const SizedBox(height: AppSpace.s4),
            Text(
              l10n.engineInfo(
                info.durationSec.toStringAsFixed(1),
                info.sampleRate,
                info.channels,
                info.sourceBitrate == null
                    ? l10n.engineBitrateUnknown
                    : l10n.engineBitrate(info.sourceBitrate!),
              ),
              style: text.caption,
            ),
            if (!info.hasAudio) ...[
              const SizedBox(height: AppSpace.s12),
              StatusBox(message: l10n.engineNoAudio, tone: StatusTone.warn),
            ],
            if (info.isProtected) ...[
              const SizedBox(height: AppSpace.s12),
              StatusBox(message: l10n.engineProtected, tone: StatusTone.warn),
            ],
            if (_peaks.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s16),
              AppCard(child: WaveformView(peaks: _peaks, start: 0, end: 1)),
            ],
            const SizedBox(height: AppSpace.s16),
            Row(
              children: [
                TextLinkButton(
                  label: l10n.engineConvertAll,
                  onPressed: _busy || !info.hasAudio || info.isProtected
                      ? null
                      : _convertAll,
                ),
                const Spacer(),
                if (_busy && _jobId != null)
                  TextLinkButton(
                    label: l10n.cancel,
                    muted: true,
                    onPressed: () => _engine.cancel(_jobId!),
                  ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: AppSpace.s8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.badge),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: colors.surface2,
                  color: colors.accent,
                ),
              ),
            ],
          ],
          if (_outcomes.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s16),
            ListGroup(
              children: [
                for (final outcome in _outcomes) _outcomeRow(context, outcome),
              ],
            ),
          ],
          if (_savedMessage != null) ...[
            const SizedBox(height: AppSpace.s12),
            StatusBox(message: _savedMessage!, tone: StatusTone.info),
          ],
        ],
      ),
    );
  }

  Widget _outcomeRow(BuildContext context, _Outcome outcome) {
    final l10n = AppLocalizations.of(context);
    final text = context.appText;
    final label = _formatLabel(l10n, outcome.format);
    final result = outcome.result;
    final String line;
    if (outcome.unavailable) {
      line = l10n.engineUnavailable(label);
    } else if (result == null) {
      line = l10n.engineFailed(label, outcome.error ?? '');
    } else {
      line = l10n.engineResult(
        label,
        _formatBytes(result.outputBytes),
        result.seconds.toStringAsFixed(1),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s16,
        vertical: AppSpace.s8,
      ),
      child: Row(
        children: [
          Expanded(child: Text(line, style: text.body)),
          if (result != null) ...[
            IconSquareButton(
              icon: _playing == result.outputPath
                  ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                  : PhosphorIcons.play(PhosphorIconsStyle.fill),
              semanticLabel: _playing == result.outputPath
                  ? l10n.pause
                  : l10n.play,
              onPressed: () => _togglePlay(result.outputPath),
            ),
            const SizedBox(width: AppSpace.s8),
            IconSquareButton(
              icon: PhosphorIcons.export(),
              semanticLabel: l10n.share,
              onPressed: () => _share(result.outputPath),
            ),
            const SizedBox(width: AppSpace.s8),
            IconSquareButton(
              icon: PhosphorIcons.folders(),
              semanticLabel: l10n.engineCopyToFolder,
              onPressed: () => _saveToFolder(result.outputPath),
            ),
          ],
        ],
      ),
    );
  }
}

class _Outcome {
  const _Outcome(
    this.format, {
    this.result,
    this.error,
    this.unavailable = false,
  });

  final OutFormat format;
  final ConvertResult? result;
  final String? error;
  final bool unavailable;
}

String _baseName(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

String _formatBytes(int bytes) {
  const mb = 1024 * 1024;
  if (bytes >= 1024 * mb) {
    return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
  }
  final value = bytes / mb;
  return value >= 10 ? '${value.round()} MB' : '${value.toStringAsFixed(1)} MB';
}

String _formatLabel(AppLocalizations l10n, OutFormat format) {
  return switch (format) {
    OutFormat.mp3 => l10n.formatMp3,
    OutFormat.m4a => l10n.formatM4a,
    OutFormat.wav => l10n.formatWav,
    OutFormat.m4r => l10n.formatM4r,
    OutFormat.flac => l10n.formatFlac,
    OutFormat.aac => l10n.formatAac,
    OutFormat.ogg => l10n.formatOgg,
  };
}
