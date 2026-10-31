import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/adaptive.dart';
import 'package:tunely/app/app.dart';
import 'package:tunely/app/merge.dart';
import 'package:tunely/app/router.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/core/design_system/tab_bar.dart';

import 'support/fakes.dart';

/// iPhone Duo sizes in points (outer, inner, inner rotated) with the status
/// bar strip as a side inset, plus a regular iPhone for comparison.
const _sizes = <(String, Size, EdgeInsets)>[
  ('iphone', Size(393, 852), EdgeInsets.only(top: 59, bottom: 34)),
  ('duo outer', Size(466, 678), EdgeInsets.only(right: 50, bottom: 20)),
  ('duo inner', Size(669, 951), EdgeInsets.only(right: 50, bottom: 20)),
  ('duo rotated', Size(951, 669), EdgeInsets.only(top: 50, bottom: 20)),
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
  '/more-apps',
  '/ads-consent',
  '/invite',
  '/redeem',
  '/i/ANNA7K',
  '/account/sign-up',
  '/account/sign-in',
  '/account/reset',
];

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (_) async => <String, Object?>{},
        );
  });

  group('AdaptiveLayout', () {
    test('wide from 600 pt, by width only', () {
      expect(AdaptiveLayout.isWide(const Size(466, 678)), isFalse);
      expect(AdaptiveLayout.isWide(const Size(669, 951)), isTrue);
      expect(AdaptiveLayout.isWide(const Size(951, 669)), isTrue);
    });

    test('rail follows the larger side inset', () {
      expect(
        AdaptiveLayout.navEdge(
          const EdgeInsets.only(right: 50),
          TextDirection.ltr,
        ),
        NavEdge.right,
      );
      expect(
        AdaptiveLayout.navEdge(
          const EdgeInsets.only(left: 30),
          TextDirection.ltr,
        ),
        NavEdge.left,
      );
      expect(
        AdaptiveLayout.navEdge(EdgeInsets.zero, TextDirection.rtl),
        NavEdge.right,
      );
    });
  });

  for (final (name, size, insets) in _sizes) {
    testWidgets('$name: every main route lays out without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = FakeViewPadding(
        left: insets.left * 3,
        top: insets.top * 3,
        right: insets.right * 3,
        bottom: insets.bottom * 3,
      );
      addTearDown(tester.view.reset);

      final router = createRouter();
      addTearDown(router.dispose);
      final container = testContainer(
        engine: FakeEngine(Directory.systemTemp.createTempSync('duo')),
      );
      addTearDown(container.dispose);
      container.read(mergeProvider.notifier).add([
        for (final n in ['a.mp3', 'b.m4a', 'c.mov'])
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

      final bar = tester.widget<AppTabBar>(find.byType(AppTabBar));
      expect(bar.vertical, AdaptiveLayout.isWide(size));
      if (bar.vertical) expect(bar.railOnRight, insets.right > insets.left);

      for (final route in _routes) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$name $route');
      }
    });
  }
}
