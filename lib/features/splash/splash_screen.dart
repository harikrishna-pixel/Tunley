import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_text.dart';
import '../../l10n/app_localizations.dart';

/// Shown while `main` finishes boot. Matches LaunchScreen bg; loader + copy
/// so TestFlight users are not stuck on a blank splash with no feedback.
class TunelySplashApp extends StatelessWidget {
  const TunelySplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: colors.bg,
        colorScheme: ColorScheme.light(
          primary: colors.accent,
          surface: colors.bg,
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _SplashBody(),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.light;
    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.splashPleaseWait,
              style: AppText.from(colors).body.copyWith(color: colors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
