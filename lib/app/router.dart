import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/engine/audio_engine.dart';
import '../core/library/library_repository.dart';
import '../core/rules/account_rules.dart';
import '../features/account/account_screen.dart';
import '../features/account/auth_screens.dart';
import '../features/account/invite_screen.dart';
import '../features/account/redeem_screen.dart';
import '../features/ads/ads_consent_screen.dart';
import '../features/batch/batch_screen.dart';
import '../features/more_apps/more_apps_screen.dart';
import '../features/merge/merge_screen.dart';
import '../features/convert/convert_screen.dart';
import '../features/debug/component_gallery_screen.dart';
import '../features/debug/engine_debug_screen.dart';
import '../features/errors/error_screen.dart';
import '../features/home/home_screen.dart';
import '../features/my_files/my_files_screen.dart';
import '../features/picker/picker_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/result/result_screen.dart';
import '../features/help/help_screen.dart';
import '../features/offers/offer_screens.dart';
import '../features/paywall/paywall_screen.dart';
import 'monetization.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/preferences/preferences_screen.dart';
import '../features/ringtone_guide/ringtone_guide_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/trim/trim_screen.dart';
import 'shell.dart';
import 'transitions.dart';

GoRoute _push(String path, Widget Function(GoRouterState state) build) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => AppTransitions.push(
      key: state.pageKey,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      child: build(state),
    ),
  );
}

GoRoute _tab(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => AppTransitions.tabCrossFade(
      key: state.pageKey,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      child: child,
    ),
  );
}

GoRouter createRouter({bool onboarded = true}) {
  return GoRouter(
    initialLocation: onboarded ? '/home' : '/onboarding',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [_tab('/home', const HomeScreen())]),
          StatefulShellBranch(routes: [_tab('/files', const MyFilesScreen())]),
          StatefulShellBranch(
            routes: [_tab('/settings', const SettingsScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: PaywallScreen(
            source: state.extra as PaywallSource? ?? PaywallSource.proChip,
          ),
        ),
      ),
      GoRoute(
        path: '/trial-reminder',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: TrialReminderScreen(entry: state.extra as String? ?? 'in_app'),
        ),
      ),
      GoRoute(
        path: '/winback',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: const WinBackScreen(),
        ),
      ),
      GoRoute(
        path: '/ads-consent',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: const AdsConsentScreen(),
        ),
      ),
      _push(
        '/more-apps',
        (state) => MoreAppsScreen(entry: state.extra as String? ?? 'settings'),
      ),
      GoRoute(
        path: '/invite',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: InviteScreen(source: state.extra as String? ?? 'settings'),
        ),
      ),
      GoRoute(
        path: '/redeem',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: RedeemScreen(
            args: state.extra as RedeemArgs? ?? const RedeemArgs(),
          ),
        ),
      ),
      // Universal link https://tunely.app/i/<CODE> (`12` §4).
      GoRoute(
        path: '/i/:code',
        pageBuilder: (context, state) => AppTransitions.modalUp(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: RedeemScreen(
            args: RedeemArgs(
              code: ReferralCode.normalize(state.pathParameters['code'] ?? ''),
              fromLink: true,
            ),
          ),
        ),
      ),
      _push('/account', (_) => const AccountScreen()),
      _push('/account/sign-up', (_) => const SignUpScreen()),
      _push('/account/sign-in', (_) => const SignInScreen()),
      _push(
        '/account/reset',
        (state) => ResetPasswordScreen(email: state.extra as String? ?? ''),
      ),
      _push('/account/delete', (_) => const DeleteAccountScreen()),
      _push('/preferences', (_) => const PreferencesScreen()),
      _push('/about', (_) => const AboutScreen()),
      _push(
        '/help',
        (state) => HelpScreen(initialSlug: state.extra as String?),
      ),
      _push('/help/garageband', (_) => const GarageBandScreen()),
      _push(
        '/guide',
        (state) => RingtoneGuideScreen(item: state.extra as LibraryItem?),
      ),
      _push(
        '/pick',
        (state) => PickerScreen(
          intent: state.extra as PickerIntent? ?? const PickerIntent(),
        ),
      ),
      _push('/convert', (_) => const ConvertScreen()),
      _push(
        '/trim',
        (state) {
          final extra = state.extra;
          final args = extra is TrimRouteArgs
              ? extra
              : TrimRouteArgs(asEntry: extra == true);
          return TrimScreen(
            asEntry: args.asEntry,
            focusBoost: args.focusBoost,
          );
        },
      ),
      _push('/merge', (_) => const MergeScreen()),
      _push('/batch', (_) => const BatchScreen()),
      GoRoute(
        path: '/batch/done',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: const BatchDoneScreen(),
        ),
      ),
      _push(
        '/progress',
        (state) => ProgressScreen(compatibility: state.extra == true),
      ),
      GoRoute(
        path: '/result',
        pageBuilder: (context, state) => AppTransitions.fadeThrough(
          key: state.pageKey,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          child: ResultScreen(item: state.extra! as LibraryItem),
        ),
      ),
      _push(
        '/item',
        (state) => ResultScreen(item: state.extra! as LibraryItem),
      ),
      _push(
        '/error',
        (state) => ErrorScreen(
          args: switch (state.extra) {
            final ErrorArgs args => args,
            final EngineErrorCode code => ErrorArgs(code),
            _ => const ErrorArgs(EngineErrorCode.unknown),
          },
        ),
      ),
      if (kDebugMode) ...[
        _push('/debug/gallery', (_) => const ComponentGalleryScreen()),
        _push('/debug/engine', (_) => const EngineDebugScreen()),
      ],
    ],
  );
}
