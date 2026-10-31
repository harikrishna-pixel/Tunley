import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

class TunelyApp extends StatelessWidget {
  const TunelyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeModeProvider);
        return MaterialApp.router(
          title: 'Tunely',
          debugShowCheckedModeBanner: false,
          theme: buildTunelyTheme(AppColors.light),
          darkTheme: buildTunelyTheme(AppColors.dark),
          themeMode: themeMode,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
