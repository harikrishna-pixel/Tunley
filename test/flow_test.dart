import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/core/library/app_database.dart';
import 'package:tunely/core/library/usage_store.dart';
import 'package:tunely/core/rules/free_limit.dart';
import 'package:tunely/core/rules/personalization.dart';
import 'package:tunely/core/rules/ringtone_rules.dart';

import 'package:tunely/features/errors/error_screen.dart';

import 'support/fakes.dart';

SourceFile _source({double seconds = 42}) => SourceFile(
  path: '/tmp/clip.mov',
  name: 'Dance_night.mov',
  info: fakeInfo(seconds: seconds),
);

void main() {
  group('draft', () {
    test('ringtone mode selects at most 30 seconds with fades on', () {
      final container = testContainer();
      addTearDown(container.dispose);
      final drafts = container.read(draftProvider.notifier);
      drafts.start(_source(seconds: 120), mode: ConvertMode.ringtone);
      drafts.setPeaks(List.generate(60, (i) => i == 45 ? 1.0 : 0.1));

      final draft = container.read(draftProvider)!;
      expect(draft.outputFormat, OutFormat.m4r);
      expect(draft.seconds, closeTo(30, 0.5));
      expect(draft.fadeIn && draft.fadeOut, isTrue);
      expect(draft.estimate().label, '~0.5 MB');
    });

    test('audio mode defaults to MP3 High over the full file', () {
      final container = testContainer();
      addTearDown(container.dispose);
      container
          .read(draftProvider.notifier)
          .start(_source(), mode: ConvertMode.audioFile);

      final draft = container.read(draftProvider)!;
      expect(draft.outputFormat, OutFormat.mp3);
      expect(draft.bitrateKbps, 256);
      expect(draft.isTrimmed, isFalse);
      expect(draft.estimate().label, '~1.3 MB');
      expect(draft.requestsPro, isFalse);
    });

    test('pro formats, tones and boost request the pro gate', () {
      final container = testContainer();
      addTearDown(container.dispose);
      final drafts = container.read(draftProvider.notifier);
      drafts.start(_source(), mode: ConvertMode.audioFile);
      drafts.update((d) => d.copyWith(format: OutFormat.flac));
      expect(container.read(draftProvider)!.requestsPro, isTrue);
      drafts.update((d) => d.copyWith(format: OutFormat.mp3, boost: true));
      expect(container.read(draftProvider)!.requestsPro, isTrue);
      drafts.setMode(ConvertMode.ringtone);
      drafts.update((d) => d.copyWith(boost: false));
      drafts.setTone(ToneType.alarm);
      expect(container.read(draftProvider)!.requestsPro, isTrue);
    });
  });

  group('job', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('tunely_job'));

    Future<(FakeEngine, dynamic)> run({
      EngineErrorCode? failWith,
      bool deleteOutput = false,
    }) async {
      final engine = FakeEngine(dir)
        ..failWith = failWith
        ..deleteOutput = deleteOutput;
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      final drafts = container.read(draftProvider.notifier);
      drafts.start(_source(), mode: ConvertMode.audioFile);
      await container
          .read(jobProvider.notifier)
          .start(container.read(draftProvider)!);
      return (engine, container);
    }

    test(
      'a successful conversion counts once and lands in the library',
      () async {
        final (engine, container) = await run();
        final job = container.read(jobProvider)!;
        expect(job.status, JobStatus.succeeded);
        expect(container.read(freeLimitProvider).usedToday, 1);
        final items = await container.read(libraryRepositoryProvider).list();
        expect(items, hasLength(1));
        expect(items.single.name, 'Dance_night.mp3');
        expect(engine.requests.single.bitrateKbps, 256);
        expect(engine.requests.single.endSec, 0);
      },
    );

    test('failed and cancelled conversions never count', () async {
      for (final code in [EngineErrorCode.cancelled, EngineErrorCode.decode]) {
        final (_, container) = await run(failWith: code);
        expect(container.read(jobProvider)!.status, JobStatus.failed);
        expect(container.read(jobProvider)!.error, code);
        expect(container.read(freeLimitProvider).usedToday, 0);
        expect(await container.read(libraryRepositoryProvider).count(), 0);
      }
    });

    test(
      'compatibility mode reaches the engine and failures keep progress',
      () async {
        final engine = FakeEngine(dir)..failWith = EngineErrorCode.decode;
        final container = testContainer(engine: engine);
        addTearDown(container.dispose);
        container
            .read(draftProvider.notifier)
            .start(_source(), mode: ConvertMode.audioFile);
        await container
            .read(jobProvider.notifier)
            .start(container.read(draftProvider)!, compatibility: true);
        final job = container.read(jobProvider)!;
        expect(engine.requests.single.compatibilityMode, isTrue);
        expect(job.compatibility, isTrue);
        expect(job.fraction, 0.5);
        expect(audCode(job.error!), 'AUD-DEC-01');
      },
    );

    test('delete removes the library copy only', () async {
      final (_, container) = await run();
      final repo = container.read(libraryRepositoryProvider);
      final item = (await repo.list()).single;
      final copy = File('${dir.path}/Tunely folder/${item.name}')
        ..createSync(recursive: true)
        ..writeAsStringSync('copy');
      final libraryFile = File(repo.absolutePath(item));
      expect(libraryFile.existsSync(), isTrue);

      await repo.delete(item);
      expect(libraryFile.existsSync(), isFalse);
      expect(copy.existsSync(), isTrue);
      expect(await repo.count(), 0);
    });

    test('a missing output file never counts', () async {
      final (_, container) = await run(deleteOutput: true);
      expect(container.read(jobProvider)!.status, JobStatus.failed);
      expect(container.read(freeLimitProvider).usedToday, 0);
    });
  });

  test('error codes follow 05 §6', () {
    expect(audCode(EngineErrorCode.decode), 'AUD-DEC-01');
    expect(audCode(EngineErrorCode.encode), 'AUD-ENC-03');
    expect(audCode(EngineErrorCode.interrupted), 'AUD-INT-04');
    expect(audCode(EngineErrorCode.io), 'AUD-IO-05');
  });

  test('usage store keeps the free limit and counters', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final store = UsageStore(db);
    final now = DateTime(2026, 10, 29, 10);
    final empty = await store.readFreeLimit(now);
    expect(empty.usedToday, 0);
    expect(empty.dayKey, '2026-10-29');

    await store.writeFreeLimit(
      const FreeLimitSnapshot(
        usedToday: 2,
        rewardedToday: 1,
        dayKey: '2026-10-29',
        maxDayKey: '2026-10-29',
      ),
    );
    final saved = await store.readFreeLimit(now);
    expect(saved.usedToday, 2);
    expect(saved.rewardedToday, 1);

    await store.recordSuccess(ringtone: true);
    await store.recordSuccess(ringtone: false);
    expect(await store.lifetimeConversions(), 2);
    expect(await store.ringtonesSaved(), 1);
  });
}
