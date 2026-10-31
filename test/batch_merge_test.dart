import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/batch.dart';
import 'package:tunely/app/merge.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/app/theme.dart';
import 'package:tunely/core/design_system/app_colors.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/features/prompts/notification_prompt.dart';
import 'package:tunely/features/prompts/rating_dialog.dart';
import 'package:tunely/l10n/app_localizations.dart';

import 'support/fakes.dart';

SourceFile _source(String name, {double seconds = 42}) => SourceFile(
  path: '/tmp/$name',
  name: name,
  info: fakeInfo(path: '/tmp/$name', seconds: seconds),
);

final _copy = BatchCopy(
  backgroundTitle: 'Converting',
  progress: (done, total) => '$done of $total',
  doneTitle: 'Tunely',
  doneBody: (n) => '$n files converted',
);

Future<void> _settle(ProviderContainer container) async {
  for (var i = 0; i < 50 && container.read(batchProvider)!.running; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FakeEngine engine;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tunely_batch');
    engine = FakeEngine(dir);
  });

  group('Batch', () {
    test(
      'one failure never stops the queue; finished files are saved',
      () async {
        final container = testContainer(engine: engine);
        addTearDown(container.dispose);
        engine.failPaths.add('/tmp/b.mov');
        engine.failPathsWith = EngineErrorCode.icloud;

        await container.read(batchProvider.notifier).start([
          _source('a.mov'),
          _source('b.mov'),
          _source('c.mov'),
        ], _copy);
        await _settle(container);

        final batch = container.read(batchProvider)!;
        expect(batch.finished, isTrue);
        expect(batch.done, 2);
        expect(batch.failed, 1);
        expect(batch.items[1].error, EngineErrorCode.icloud);
        expect(engine.requests.map((r) => r.inputs.single), [
          '/tmp/a.mov',
          '/tmp/b.mov',
          '/tmp/c.mov',
        ]);
        final library = await container.read(libraryRepositoryProvider).list();
        expect(library, hasLength(2));
        // Batch is Pro: it never touches the free counter.
        expect(container.read(freeLimitProvider).usedToday, 0);
      },
    );

    test('Retry failed re-runs only the failed files', () async {
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      engine.failPaths.add('/tmp/b.mov');
      final batch = container.read(batchProvider.notifier);
      await batch.start([_source('a.mov'), _source('b.mov')], _copy);
      await _settle(container);
      expect(container.read(batchProvider)!.failed, 1);

      engine.failPaths.clear();
      engine.requests.clear();
      await batch.retryFailed();
      await _settle(container);

      expect(engine.requests.map((r) => r.inputs.single), ['/tmp/b.mov']);
      expect(container.read(batchProvider)!.done, 2);
      expect(container.read(batchProvider)!.failed, 0);
    });

    test('iOS 26 uses continued processing and finishes it', () async {
      engine.osVersion = '26.0';
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      await container.read(batchProvider.notifier).start([
        _source('a.mov'),
      ], _copy);
      await _settle(container);
      expect(engine.continuedStarted, isTrue);
      expect(engine.continuedFinished, isTrue);
    });

    test('older iOS runs without continued processing', () async {
      engine.osVersion = '18.4';
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      await container.read(batchProvider.notifier).start([
        _source('a.mov'),
      ], _copy);
      await _settle(container);
      expect(engine.continuedStarted, isFalse);
      expect(container.read(batchProvider)!.done, 1);
    });

    test('caps the batch at batchMaxFiles', () async {
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      await container.read(batchProvider.notifier).start([
        for (var i = 0; i < 60; i++) _source('f$i.mov', seconds: 1),
      ], _copy);
      expect(container.read(batchProvider)!.total, 50);
      await _settle(container);
    });
  });

  group('Merge', () {
    test('adds without duplicates up to 10 and reorders', () {
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      final merge = container.read(mergeProvider.notifier);
      merge.add([_source('a.mp3'), _source('b.mp3'), _source('a.mp3')]);
      expect(container.read(mergeProvider).files, hasLength(2));
      merge.add([for (var i = 0; i < 12; i++) _source('x$i.mp3')]);
      expect(container.read(mergeProvider).files, hasLength(10));
      merge.reorder(0, 1);
      expect(container.read(mergeProvider).files.take(2).map((f) => f.name), [
        'b.mp3',
        'a.mp3',
      ]);
      merge.remove(0);
      expect(container.read(mergeProvider).files.first.name, 'a.mp3');
    });

    test('runs one request with inputs in order and the crossfade', () async {
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      final merge = container.read(mergeProvider.notifier)
        ..add([
          _source('a.mp3', seconds: 72),
          _source('b.m4a', seconds: 38),
          _source('c.mov', seconds: 42),
        ])
        ..setCrossfade(2);
      expect(container.read(mergeProvider).totalSeconds, 148);
      expect(merge.room, 7);

      final draft = container.read(mergeProvider).draft('Tunely merge')!;
      await container.read(jobProvider.notifier).start(draft);

      final request = engine.requests.single;
      expect(request.inputs, ['/tmp/a.mp3', '/tmp/b.m4a', '/tmp/c.mov']);
      expect(request.crossfadeSec, 2);
      expect(request.outputName, 'Tunely merge');
      expect(container.read(jobProvider)!.status, JobStatus.succeeded);
      // One merge has no free-limit impact (05 §11).
      expect(container.read(freeLimitProvider).usedToday, 0);
    });

    test('needs at least 2 files', () {
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      container.read(mergeProvider.notifier).add([_source('a.mp3')]);
      expect(container.read(mergeProvider).draft('x'), isNull);
    });
  });

  group('Prompts', () {
    Widget host(ProviderContainer container, Widget child) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTunelyTheme(AppColors.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('notification pre-prompt shows once per reason', (
      tester,
    ) async {
      final reminder = FakeTrialReminder()..granted = false;
      final container = testContainer(engine: engine, reminder: reminder);
      addTearDown(container.dispose);
      bool? result;
      await tester.pumpWidget(
        host(
          container,
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async => result = await askNotifications(
                context,
                ref,
                NotifyReason.batch,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text("Get a ping when it's done"), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(reminder.permissionRequests, 0);

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text("Get a ping when it's done"), findsNothing);
      expect(result, isFalse);
    });

    testWidgets('Turn on asks iOS; denial means never again', (tester) async {
      final reminder = FakeTrialReminder()
        ..granted = false
        ..allowed = false;
      final container = testContainer(engine: engine, reminder: reminder);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        host(
          container,
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  askNotifications(context, ref, NotifyReason.trial),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(
        find.text('Get a reminder before your trial ends'),
        findsOneWidget,
      );
      await tester.tap(find.text('Turn on notifications'));
      await tester.pumpAndSettle();
      expect(reminder.permissionRequests, 1);
      final used = await container.read(usageStoreProvider).notifyPrompts();
      expect(used, containsAll(['trial', 'denied']));
    });

    testWidgets('rating CTA follows the stars', (tester) async {
      final container = testContainer(engine: engine);
      addTearDown(container.dispose);
      await tester.pumpWidget(host(container, const RatingDialog()));
      expect(find.text('Rate on the App Store'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('2 stars'));
      await tester.pump();
      expect(find.text('Tell us what to improve'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('4 stars'));
      await tester.pump();
      expect(find.text('Rate on the App Store'), findsOneWidget);
    });
  });
}
