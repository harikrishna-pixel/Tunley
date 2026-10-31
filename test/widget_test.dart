import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/app.dart';
import 'package:tunely/app/router.dart';
import 'package:tunely/app/theme.dart';
import 'package:tunely/core/design_system/app_colors.dart';
import 'package:tunely/core/design_system/free_counter.dart';
import 'package:tunely/l10n/app_localizations.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('shell opens the component gallery from Settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createRouter();
    addTearDown(router.dispose);
    final container = testContainer(
      engine: FakeEngine(Directory.systemTemp.createTempSync('tunely_widget')),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TunelyApp(router: router),
      ),
    );

    expect(find.text('Tunely'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Make a ringtone from any video'), findsOneWidget);
    expect(find.text('3 of 3 free today'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Component gallery'), findsOneWidget);
    await tester.tap(find.text('Component gallery'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/debug/gallery');
    expect(find.text('Continue'), findsWidgets);
    expect(find.text('Make a ringtone from any video'), findsOneWidget);
  });

  testWidgets('free counter uses warn colour when none remain', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTunelyTheme(AppColors.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: FreeCounter(remaining: 0, total: 3)),
      ),
    );

    final text = tester.widget<Text>(find.text('0 of 3 free today'));
    expect(text.style?.color, AppColors.light.warn);
  });
}
