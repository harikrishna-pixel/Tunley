import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/monetization.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/format.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/analytics/values.dart';
import '../../l10n/app_localizations.dart';
import '../common/media_widgets.dart';
import '../help/help_screen.dart';

// TODO(question #10): confirm the support address.
const supportEmail = 'support@marberx.com';

/// What the user picked on an error screen.
enum ErrorChoice { retry, another }

class ErrorArgs {
  const ErrorArgs(
    this.code, {
    this.missingMb,
    this.requiredBytes,
    this.sourceName,
    this.sourceBytes,
    this.isVideo = true,
    this.percent,
    this.retriedCompatibility = false,
    this.variableFrameRate = false,
  });

  final EngineErrorCode code;

  /// The source video has a variable frame rate (AUD-VFR-02).
  final bool variableFrameRate;
  final int? missingMb;
  final int? requiredBytes;
  final String? sourceName;
  final int? sourceBytes;
  final bool isVideo;

  /// How far the job got before it failed (E1).
  final int? percent;
  final bool retriedCompatibility;

  ErrorArgs withMissing(int mb) => ErrorArgs(
    code,
    missingMb: mb,
    requiredBytes: requiredBytes,
    sourceName: sourceName,
    sourceBytes: sourceBytes,
    isVideo: isVideo,
    percent: percent,
    retriedCompatibility: retriedCompatibility,
    variableFrameRate: variableFrameRate,
  );

  String get audCode => auCode(code, variableFrameRate: variableFrameRate);
}

/// Error codes shown small on E1 and attached to support mail (`05` §6).
String audCode(EngineErrorCode code) => auCode(code);

/// A decode/encode failure on a variable-frame-rate video is AUD-VFR-02; E1's
/// compatibility mode (Apple's exporter) is the fix.
String auCode(EngineErrorCode code, {bool variableFrameRate = false}) =>
    switch (code) {
      EngineErrorCode.decode ||
      EngineErrorCode.encode ||
      EngineErrorCode.unknown when variableFrameRate => 'AUD-VFR-02',
      EngineErrorCode.encode || EngineErrorCode.unavailable => 'AUD-ENC-03',
      EngineErrorCode.interrupted => 'AUD-INT-04',
      EngineErrorCode.io || EngineErrorCode.staleBookmark => 'AUD-IO-05',
      _ => 'AUD-DEC-01',
    };

/// E1–E4: what happened, the original is safe, one primary next step.
class ErrorScreen extends ConsumerStatefulWidget {
  const ErrorScreen({super.key, required this.args});

  final ErrorArgs args;

  @override
  ConsumerState<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends ConsumerState<ErrorScreen> {
  late ErrorArgs _args = widget.args;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(paywallProvider.notifier).noteError());
    ref.read(analyticsProvider).errorShown(type: _type, code: _args.audCode);
  }

  String get _type => AnalyticsValues.errorScreen(_args.code);

  void _action(String action) => ref
      .read(analyticsProvider)
      .errorRecoveryAction(type: _type, action: action);

  void _close([ErrorChoice? choice]) {
    switch (choice) {
      case ErrorChoice.retry:
        _action('retry');
      case ErrorChoice.another:
        _action('pick_another');
      case null:
        break;
    }
    Navigator.of(context).pop(choice);
  }

  Future<void> _checkSpace() async {
    final required = _args.requiredBytes;
    if (required == null) return _close(ErrorChoice.retry);
    setState(() => _checking = true);
    final free = await ref.read(audioEngineProvider).freeBytes();
    if (!mounted) return;
    setState(() => _checking = false);
    if (free >= required) {
      _close(ErrorChoice.retry);
      return;
    }
    const mb = 1024 * 1024;
    final missing = ((required - free) + mb - 1) ~/ mb;
    setState(() => _args = _args.withMissing(missing));
    TunelyToast.show(
      context,
      message: AppLocalizations.of(context).e2StillShort(missing),
      tone: ToastTone.warning,
    );
  }

  void _compatibility() {
    _action('compatibility_mode');
    context.pushReplacement('/progress', extra: true);
  }

  Future<void> _contactSupport() async {
    await Clipboard.setData(
      ClipboardData(text: '$supportEmail · ${_args.audCode}'),
    );
    if (!mounted) return;
    await contactSupport(
      context,
      ref,
      errorCode: _args.audCode,
      screen: 'error',
    );
  }

  void _infoSheet(String title, String body) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: sheetContext.appText.dialogTitle),
          const SizedBox(height: AppSpace.s8),
          Text(
            body,
            style: sheetContext.appText.body.copyWith(
              color: sheetContext.colors.text2,
            ),
          ),
          const SizedBox(height: AppSpace.s20),
          PrimaryButton(
            label: AppLocalizations.of(sheetContext).ok,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final args = _args;
    final name = args.sourceName;

    final ErrorContent content = switch (args.code) {
      EngineErrorCode.noSpace => ErrorContent(
        icon: PhosphorIcons.hardDrives(),
        tone: StatusTone.warn,
        title: l10n.e2Title(args.missingMb ?? 50),
        body: l10n.e2Body,
        cardLabel: l10n.e2CardLabel,
        card: [
          l10n.e2Tip1,
          l10n.e2Tip2,
          l10n.e2Tip3,
        ].map((t) => '•  $t').join('\n'),
        primary: l10n.e2Cta,
        onPrimary: _checking ? null : _checkSpace,
        secondary: l10n.e2Help,
        onSecondary: () {
          _action('open_storage');
          _infoSheet(l10n.e2HelpTitle, l10n.e2HelpBody);
        },
      ),
      EngineErrorCode.icloud => ErrorContent(
        icon: PhosphorIcons.cloudSlash(),
        tone: StatusTone.warn,
        title: l10n.e3Title,
        body: name == null ? l10n.e3BodyGeneric : l10n.e3Body(name),
        cardLabel: args.sourceBytes == null ? null : l10n.e3CardLabel,
        card: args.sourceBytes == null
            ? null
            : l10n.e3Card(Fmt.bytes(args.sourceBytes!)),
        primary: l10n.tryAgain,
        onPrimary: () => _close(ErrorChoice.retry),
        secondary: l10n.pickAnotherFile,
        onSecondary: () => _close(ErrorChoice.another),
      ),
      EngineErrorCode.protected => ErrorContent(
        icon: PhosphorIcons.prohibit(),
        tone: StatusTone.danger,
        title: args.isVideo ? l10n.e4TitleVideo : l10n.e4TitleSong,
        body: l10n.e4Body,
        cardLabel: name == null ? null : l10n.e4CardLabel,
        card: name == null
            ? null
            : l10n.e4Card(
                Fmt.baseName(name),
                Fmt.extension(name).toLowerCase(),
              ),
        primary: l10n.chooseAnotherFile,
        onPrimary: () => _close(ErrorChoice.another),
        secondary: l10n.whatCanIConvert,
        onSecondary: () =>
            _infoSheet(l10n.convertibleTitle, l10n.convertibleBody),
      ),
      EngineErrorCode.noAudio => ErrorContent(
        icon: PhosphorIcons.speakerSlash(),
        tone: StatusTone.danger,
        title: l10n.e4bTitle,
        body: l10n.e4bBody,
        cardLabel: name == null ? null : l10n.e4CardLabel,
        card: name == null ? null : l10n.e4bCard(name),
        primary: l10n.chooseAnotherFile,
        onPrimary: () => _close(ErrorChoice.another),
        secondary: l10n.getHelp,
        onSecondary: () => _infoSheet(l10n.getHelp, l10n.noSoundHelpBody),
      ),
      _ => ErrorContent(
        icon: PhosphorIcons.x(PhosphorIconsStyle.bold),
        tone: StatusTone.danger,
        filledIcon: true,
        title: name == null ? l10n.errorUnreadableTitle : l10n.e1Title(name),
        body: args.code == EngineErrorCode.interrupted
            ? l10n.errorInterruptedBody
            : args.percent == null
            ? l10n.e1BodyNoProgress
            : l10n.e1Body(args.percent!),
        cardLabel: l10n.e1CardLabel,
        card: args.retriedCompatibility
            ? l10n.e1CardRetried(args.audCode)
            : l10n.e1Card(args.audCode),
        primary: args.retriedCompatibility
            ? l10n.chooseAnotherFile
            : l10n.e1Cta,
        onPrimary: args.retriedCompatibility
            ? () => _close(ErrorChoice.another)
            : _compatibility,
        secondary: l10n.contactSupport,
        onSecondary: _contactSupport,
      ),
    };

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: ErrorLayout(content: content, onClose: () => _close()),
      ),
    );
  }
}

class ErrorContent {
  const ErrorContent({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    required this.primary,
    required this.onPrimary,
    this.filledIcon = false,
    this.cardLabel,
    this.card,
    this.secondary,
    this.onSecondary,
  });

  final IconData icon;
  final StatusTone tone;
  final bool filledIcon;
  final String title;
  final String body;
  final String? cardLabel;
  final String? card;
  final String primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;
}

class ErrorLayout extends StatelessWidget {
  const ErrorLayout({super.key, required this.content, required this.onClose});

  final ErrorContent content;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final (soft, strong) = switch (content.tone) {
      StatusTone.warn => (colors.warnSoft, colors.warn),
      StatusTone.success => (colors.successSoft, colors.success),
      StatusTone.info => (colors.accentSoft, colors.accentOnSoft),
      StatusTone.danger => (colors.dangerSoft, colors.danger),
    };
    return Column(
      children: [
        NavHeader(
          title: '',
          leading: NavLeading.none,
          trailing: Semantics(
            button: true,
            label: l10n.close,
            child: InkResponse(
              onTap: onClose,
              radius: 24,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  color: colors.text,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.s16,
              AppSpace.screen,
              AppSpace.s24,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: content.filledIcon
                      ? Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: strong,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            content.icon,
                            color: colors.heroText,
                            size: 16,
                          ),
                        )
                      : Icon(content.icon, color: strong, size: 30),
                ),
              ),
              const SizedBox(height: AppSpace.s20),
              Semantics(
                header: true,
                child: Text(content.title, style: text.largeTitle),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                content.body,
                style: text.body.copyWith(color: colors.text2),
              ),
              if (content.card != null) ...[
                const SizedBox(height: AppSpace.s20),
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (content.cardLabel != null)
                        Text(
                          content.cardLabel!,
                          style: text.caption.copyWith(
                            color: colors.text2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: AppSpace.s4),
                      Text(content.card!, style: text.body),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.s20),
              StatusBox(message: l10n.originalSafe),
            ],
          ),
        ),
        ActionFooter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: content.primary,
                onPressed: content.onPrimary,
              ),
              if (content.secondary != null) ...[
                const SizedBox(height: AppSpace.s4),
                Center(
                  child: TextLinkButton(
                    label: content.secondary!,
                    onPressed: content.onSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
