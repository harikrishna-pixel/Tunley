import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tunely/app/app.dart';
import 'package:tunely/app/merge.dart';
import 'package:tunely/app/router.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/app/theme.dart';
import 'package:tunely/core/design_system/app_colors.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/core/library/library_repository.dart';
import 'package:tunely/core/rules/personalization.dart';
import 'package:tunely/features/convert/convert_screen.dart';
import 'package:tunely/features/errors/error_screen.dart';
import 'package:tunely/features/progress/progress_screen.dart';
import 'package:tunely/features/result/result_screen.dart';
import 'package:tunely/features/trim/trim_screen.dart';
import 'package:tunely/l10n/app_localizations.dart';

import 'support/fakes.dart';

/// Smallest supported iPhone (SE, 375×667) and a regular one.
const _phones = <(String, Size, EdgeInsets)>[
  ('iPhone SE', Size(375, 667), EdgeInsets.only(top: 20)),
  ('iPhone 17', Size(402, 874), EdgeInsets.only(top: 62, bottom: 34)),
];

const _routes = [
  '/home',
  '/files',
  '/settings',
  '/preferences',
  '/help',
  '/pick',
  '/merge',
  '/paywall',
  '/trial-reminder',
  '/winback',
  '/more-apps',
  '/ads-consent',
  '/invite',
  '/redeem',
  '/account/sign-up',
  '/account/sign-in',
  '/account/reset',
  '/onboarding',
];

void _setUp(WidgetTester tester, Size size, EdgeInsets insets) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = FakeViewPadding(
    top: insets.top * 3,
    bottom: insets.bottom * 3,
  );
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Fails with the full overflow report (which widget, how far).
void _expectClean(WidgetTester tester, String where) {
  final error = tester.takeException();
  if (error == null) return;
  final detail = error is FlutterError ? error.toStringDeep() : '$error';
  fail('$where\n${detail.split('\n').take(40).join('\n')}');
}

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (_) async => <String, Object?>{},
        );
  });

  group('Contrast (09 › App Store: captions and success ≥ 4.5:1)', () {
    for (final (name, colors) in [
      ('light', AppColors.light),
      ('dark', AppColors.dark),
    ]) {
      test('$name theme', () {
        for (final (label, fg) in [
          ('text', colors.text),
          ('text2', colors.text2),
          ('text3', colors.text3),
          ('success', colors.success),
          ('danger', colors.danger),
          ('link', colors.link),
        ]) {
          for (final (bgName, bg) in [
            ('bg', colors.bg),
            ('surface', colors.surface),
          ]) {
            expect(
              _contrast(fg, bg),
              greaterThanOrEqualTo(4.5),
              reason: '$label on $bgName',
            );
          }
        }
      });
    }
  });

  for (final (phone, size, insets) in _phones) {
    testWidgets('$phone at 200% text: every route lays out, icon buttons '
        'are labelled', (tester) async {
      _setUp(tester, size, insets);
      final handle = tester.ensureSemantics();
      final router = createRouter();
      addTearDown(router.dispose);
      final container = testContainer(
        engine: FakeEngine(Directory.systemTemp.createTempSync('a11y')),
      );
      addTearDown(container.dispose);
      container.read(mergeProvider.notifier).add([
        for (final n in ['a.mp3', 'b.m4a'])
          SourceFile(
            path: '/tmp/$n',
            name: n,
            info: fakeInfo(path: '/tmp/$n'),
          ),
      ]);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TunelyApp(router: router),
        ),
      );
      await tester.pumpAndSettle();
      for (final route in _routes) {
        router.go(route);
        await tester.pumpAndSettle();
        _expectClean(tester, '$phone $route');
        for (final button
            in find
                .byType(IconButton)
                .evaluate()
                .map((e) => e.widget as IconButton)) {
          expect(
            button.tooltip != null || button.icon is Semantics,
            isTrue,
            reason: '$route: IconButton without a label',
          );
        }
      }
      handle.dispose();
    });

    testWidgets('$phone at 200% text: core flow screens', (tester) async {
      _setUp(tester, size, insets);
      final container = testContainer(
        engine: FakeEngine(Directory.systemTemp.createTempSync('a11y')),
      );
      addTearDown(container.dispose);
      final source = SourceFile(
        path: '/tmp/Dance_night.mov',
        name: 'Dance_night.mov',
        info: fakeInfo(),
      );
      final item = LibraryItem(
        id: 'x',
        relPath: 'Library/Dance_night.mp3',
        name: 'Dance_night.mp3',
        format: 'mp3',
        bitrateKbps: 256,
        bytes: 1363148,
        durationSec: 42,
        sourceName: 'Dance_night.mov',
        sourceBytes: 86 * 1024 * 1024,
        sourceIsVideo: true,
        tookMs: 2600,
        createdAt: DateTime(2026, 10, 29),
      );
      for (final (name, screen, mode) in <(String, Widget, ConvertMode?)>[
        ('convert audio', const ConvertScreen(), ConvertMode.audioFile),
        ('convert ringtone', const ConvertScreen(), ConvertMode.ringtone),
        ('trim', const TrimScreen(), ConvertMode.ringtone),
        ('progress', const ProgressScreen(), ConvertMode.audioFile),
        ('result', ResultScreen(item: item), null),
        (
          'error',
          const ErrorScreen(
            args: ErrorArgs(EngineErrorCode.decode, sourceName: 'clip.mov'),
          ),
          null,
        ),
        (
          'no space',
          const ErrorScreen(
            args: ErrorArgs(EngineErrorCode.noSpace, missingMb: 180),
          ),
          null,
        ),
      ]) {
        if (mode != null) {
          container.read(draftProvider.notifier).start(source, mode: mode);
        }
        final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => screen)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: buildTunelyTheme(AppColors.light),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        _expectClean(tester, '$phone $name');
        await tester.pumpWidget(const SizedBox());
        router.dispose();
      }
    });
  }
}
