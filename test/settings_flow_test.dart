import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/app.dart';
import 'package:tunely/app/router.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/core/library/preferences_store.dart';
import 'package:tunely/core/rules/personalization.dart';
import 'package:tunely/features/my_files/my_files_screen.dart';
import 'package:tunely/l10n/app_localizations_en.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('first launch shows onboarding and Skip finishes it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemoryPreferencesStore(UserPrefs.initial);
    final container = testContainer(
      engine: FakeEngine(Directory.systemTemp.createTempSync('onb')),
      prefs: store,
    );
    addTearDown(container.dispose);
    final router = createRouter(onboarded: false);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TunelyApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Any video,\nyour ringtone'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MP3 from videos'));
    await tester.pump();
    expect(store.value.goal, UserGoal.mp3FromVideos);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(store.value.onboardingDone, isTrue);

    // P1 after onboarding (also after Skip), header follows the goal.
    expect(find.text('Unlimited MP3s from all your videos'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close').first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // First close of P1 → P6 exit offer, once ever.
    expect(find.text('No thanks, continue with Free'), findsOneWidget);
    await tester.tap(find.text('No thanks, continue with Free'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Turn any video into an MP3'), findsOneWidget);
  });

  test('preferences drive personalisation and draft defaults', () async {
    final container = testContainer();
    addTearDown(container.dispose);
    final prefs = container.read(preferencesProvider.notifier);
    await prefs.setGoal(UserGoal.convertFiles);
    await prefs.setDefaultFormat(OutFormat.m4a, 128);
    expect(container.read(personalizationProvider).goal, UserGoal.convertFiles);

    container
        .read(draftProvider.notifier)
        .start(
          SourceFile(
            path: '/tmp/a.wav',
            name: 'a.wav',
            info: fakeInfo(hasVideo: false),
          ),
        );
    final draft = container.read(draftProvider)!;
    expect(draft.format, OutFormat.m4a);
    expect(draft.quality, Quality.standard);
    expect(draft.isRingtone, isFalse);
  });

  test('rename changes the real file and keeps the extension', () async {
    final dir = Directory.systemTemp.createTempSync('rename');
    final container = testContainer(engine: FakeEngine(dir));
    addTearDown(container.dispose);
    container
        .read(draftProvider.notifier)
        .start(
          SourceFile(
            path: '/tmp/clip.mov',
            name: 'Dance.mov',
            info: fakeInfo(),
          ),
          mode: ConvertMode.audioFile,
        );
    await container
        .read(jobProvider.notifier)
        .start(container.read(draftProvider)!);
    final repo = container.read(libraryRepositoryProvider);
    final item = (await repo.list()).single;
    final before = File(repo.absolutePath(item));
    expect(before.existsSync(), isTrue);

    expect(await repo.rename(item, 'Party mix'), isTrue);
    final renamed = (await repo.list()).single;
    expect(renamed.name, 'Party mix.mp3');
    expect(before.existsSync(), isFalse);
    expect(File(repo.absolutePath(renamed)).existsSync(), isTrue);
    expect(await repo.rename(renamed, '  '), isFalse);
  });

  test('relative dates in My files', () {
    final l10n = AppLocalizationsEn();
    final now = DateTime(2026, 10, 29, 12);
    expect(
      relativeDate(l10n, DateTime(2026, 10, 29, 11, 40), now: now),
      'just now',
    );
    expect(
      relativeDate(l10n, DateTime(2026, 10, 28, 9), now: now),
      'yesterday',
    );
    expect(relativeDate(l10n, DateTime(2026, 10, 20, 9), now: now), 'Oct 20');
  });
}
