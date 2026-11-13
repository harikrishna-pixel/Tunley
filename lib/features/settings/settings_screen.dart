import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../../app/account.dart';
import '../../app/ads.dart';
import '../../app/config.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/rules/personalization.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../l10n/app_localizations.dart';
import '../../app/monetization.dart';
import '../account/account_widgets.dart';
import '../paywall/checkout.dart';
import '../paywall/paywall_screen.dart';
import '../paywall/pro_gate.dart';

const termsUrl = 'https://marberx.com/apps_terms_conditions.html';
const privacyUrl = 'https://marberx.com/apps_privacy_policy.html';
const manageSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';

final _folderNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  final id = await ref.watch(usageStoreProvider).folderBookmark();
  if (id == null) return null;
  return ref.watch(audioEngineProvider).bookmarkedFolderName(id);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String url) async {
    final opened = await ref.read(audioEngineProvider).openUrl(url);
    if (!opened && context.mounted) {
      TunelyToast.show(
        context,
        message: AppLocalizations.of(context).couldNotOpen,
        tone: ToastTone.warning,
      );
    }
  }

  Future<void> _chooseFolder(WidgetRef ref) async {
    final id = await ref.read(audioEngineProvider).pickFolder();
    if (id == null) return;
    await ref.read(usageStoreProvider).setFolderBookmark(id);
    ref.invalidate(_folderNameProvider);
    final icloud = await ref
        .read(audioEngineProvider)
        .bookmarkedFolderIsICloud(id);
    ref.read(analyticsProvider)
      ..saveFolderChosen(isIcloud: icloud)
      ..preferencesChanged(field: 'save_folder', value: 'changed');
  }

  /// Settings › Rate Tunely: in-app App Store page (SKStoreProductViewController).
  /// Never openStoreListing — that leaves the app / opens Safari.
  Future<void> _rate(WidgetRef ref) async {
    final id = ref.read(appConfigProvider).appStoreId;
    if (id != null) {
      final opened = await ref.read(audioEngineProvider).openAppStorePage(id);
      if (opened) return;
    }
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final isPro = ref.watch(isProProvider);
    final prefs = ref.watch(preferencesProvider);
    final folder = ref.watch(_folderNameProvider).value;

    String goalLabel(UserGoal goal) => switch (goal) {
      UserGoal.ringtones => l10n.goalRingtones,
      UserGoal.mp3FromVideos => l10n.goalMp3,
      UserGoal.convertFiles => l10n.goalConvert,
    };
    final goal = [
      for (final g in const [
        UserGoal.ringtones,
        UserGoal.mp3FromVideos,
        UserGoal.convertFiles,
      ])
        if (prefs.goals.contains(g)) goalLabel(g),
    ].join(', ');
    final format =
        prefs.defaultFormat == OutFormat.wav ||
            prefs.defaultFormat == OutFormat.flac
        ? prefs.defaultFormat.name.toUpperCase()
        : l10n.formatKbps(
            prefs.defaultFormat.name.toUpperCase(),
            prefs.defaultKbps,
          );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpace.s16, 0, AppSpace.s8),
      child: Text(
        title,
        style: text.caption.copyWith(
          color: colors.text2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s12,
        AppSpace.screen,
        AppSpace.s24,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(l10n.tabSettings, style: text.largeTitle),
        ),
        const SizedBox(height: AppSpace.s16),
        const _AccountCard(),
        const SizedBox(height: AppSpace.s12),
        if (!isPro)
          _ProCard(onTap: () => openPaywall(context, PaywallSource.settings)),
        section(l10n.settingsPreferences),
        ListGroup(
          children: [
            SettingsRow(
              icon: PhosphorIcons.slidersHorizontal(),
              label: l10n.settingsWhatIMake,
              value: goal,
              onTap: () => context.push('/preferences'),
            ),
            SettingsRow(
              icon: PhosphorIcons.fileAudio(),
              label: l10n.settingsDefaultFormat,
              value: format,
              onTap: () => showDefaultFormatSheet(context, ref),
            ),
            SettingsRow(
              icon: PhosphorIcons.folder(),
              label: l10n.settingsSaveTo,
              value: folder == null
                  ? l10n.settingsSaveToNone
                  : l10n.settingsSaveToFolder(folder),
              onTap: () => _chooseFolder(ref),
            ),
          ],
        ),
        section(l10n.settingsHelpMore),
        ListGroup(
          children: [
            // Referral API not ready (apiBaseUrl TBD). Hide invite / redeem
            // until rewards actually work — otherwise we promise Pro we can't grant.
            // SettingsRow(
            //   icon: PhosphorIcons.gift(),
            //   label: l10n.settingsInvite,
            //   value: l10n.settingsInviteDetail,
            //   valueHighlight: true,
            //   onTap: () => context.push('/invite', extra: 'settings'),
            // ),
            // SettingsRow(
            //   icon: PhosphorIcons.key(),
            //   label: l10n.settingsHaveCode,
            //   onTap: () => context.push('/redeem'),
            // ),
            SettingsRow(
              icon: PhosphorIcons.bellRinging(),
              label: l10n.settingsHowRingtone,
              onTap: () async {
                final os = await ref.read(audioEngineProvider).appInfo();
                ref
                    .read(analyticsProvider)
                    .guideOpened(entry: 'settings', iosVersion: os.osVersion);
                if (context.mounted) context.push('/guide');
              },
            ),
            SettingsRow(
              icon: PhosphorIcons.chatCircleDots(),
              label: l10n.settingsHelp,
              onTap: () => context.push('/help'),
            ),
            SettingsRow(
              icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
              label: l10n.settingsRate,
              onTap: () => _rate(ref),
            ),
            SettingsRow(
              icon: PhosphorIcons.squaresFour(),
              label: l10n.settingsMoreApps,
              onTap: () => context.push('/more-apps', extra: 'settings'),
            ),
            SettingsRow(
              icon: PhosphorIcons.info(),
              label: l10n.settingsAbout,
              onTap: () => context.push('/about'),
            ),
          ],
        ),
        section(l10n.settingsSubscription),
        ListGroup(
          children: [
            SettingsRow(
              icon: PhosphorIcons.arrowCounterClockwise(),
              label: l10n.settingsRestore,
              onTap: () {
                ref.read(analyticsProvider).restoreTapped();
                restorePurchases(context, ref);
              },
            ),
            SettingsRow(
              icon: PhosphorIcons.creditCard(),
              label: l10n.settingsManage,
              onTap: () {
                ref
                    .read(analyticsProvider)
                    .manageSubscriptionTapped(screen: 'settings');
                _open(
                  context,
                  ref,
                  ref.read(entitlementProvider).managementUrl ??
                      manageSubscriptionsUrl,
                );
              },
            ),
          ],
        ),
        if (kDebugMode) ...[
          section(l10n.settingsDebug),
          ListGroup(
            children: [
              SettingsRow(
                icon: PhosphorIcons.crown(PhosphorIconsStyle.fill),
                label: isPro ? l10n.debugLockPro : l10n.debugUnlockPro,
                onTap: () async {
                  final unlock = !isPro;
                  await ref
                      .read(purchasesServiceProvider)
                      .setDebugPro(unlock);
                  await ref.read(paywallProvider.notifier).cachePro(unlock);
                },
              ),
              SettingsRow(
                icon: PhosphorIcons.squaresFour(),
                label: l10n.galleryTitle,
                onTap: () => context.push('/debug/gallery'),
              ),
              SettingsRow(
                icon: PhosphorIcons.waveform(),
                label: l10n.engineDebugTitle,
                onTap: () => context.push('/debug/engine'),
              ),
              SettingsRow(
                icon: PhosphorIcons.megaphone(),
                label: l10n.debugLevelPlayTestSuite,
                onTap: () async {
                  await ref.read(adsProvider.notifier).start();
                  await LevelPlay.launchTestSuite();
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Account row (23): optional, only for invite rewards (`12`). Signed out it
/// opens 46, which explains before any form.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final user = ref.watch(accountProvider).user;
    return Semantics(
      button: true,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          // Invite rewards API not ready — signed-out account used to open
          // Invite friends. Keep signed-in → account; signed-out → toast.
          onTap: () {
            if (user != null) {
              context.push('/account');
              return;
            }
            TunelyToast.show(
              context,
              message: l10n.redeemUnavailable,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                if (user == null)
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.user(),
                      color: colors.accentOnSoft,
                      size: 22,
                    ),
                  )
                else
                  InitialsAvatar(user: user, size: 44),
                const SizedBox(width: AppSpace.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user == null
                            ? l10n.settingsAccountSignedOut
                            : '${user.firstName} ${user.lastName}',
                        style: text.subhead.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        user?.email ?? l10n.settingsAccountOptional,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.caption.copyWith(color: colors.text2),
                      ),
                    ],
                  ),
                ),
                PhosphorIcon(
                  PhosphorIcons.caretRight(),
                  color: colors.text3,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return Semantics(
      button: true,
      child: Material(
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(gradient: colors.heroGradient),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x29FFFFFF),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.crown(PhosphorIconsStyle.fill),
                      color: colors.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.proCardTitle,
                          style: text.navTitle.copyWith(color: colors.heroText),
                        ),
                        Text(
                          l10n.proCardBody,
                          style: text.caption.copyWith(
                            color: const Color(0xD9FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PhosphorIcon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    color: colors.heroText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings › Default format: free formats for free users, all for Pro.
Future<void> showDefaultFormatSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(
    context: context,
    builder: (sheetContext) => const _DefaultFormatSheet(),
  );
}

class _DefaultFormatSheet extends ConsumerStatefulWidget {
  const _DefaultFormatSheet();

  @override
  ConsumerState<_DefaultFormatSheet> createState() =>
      _DefaultFormatSheetState();
}

class _DefaultFormatSheetState extends ConsumerState<_DefaultFormatSheet> {
  late OutFormat _format = ref.read(preferencesProvider).defaultFormat;
  late int _kbps = ref.read(preferencesProvider).defaultKbps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.appText;
    final isPro = ref.watch(isProProvider);
    final formats = [
      OutFormat.mp3,
      OutFormat.m4a,
      OutFormat.wav,
      OutFormat.flac,
      OutFormat.aac,
      OutFormat.ogg,
    ];
    final lossless = _format == OutFormat.wav || _format == OutFormat.flac;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.defaultFormatTitle, style: text.dialogTitle),
        const SizedBox(height: AppSpace.s6),
        Text(
          l10n.defaultFormatBody,
          style: text.body.copyWith(color: context.colors.text2),
        ),
        const SizedBox(height: AppSpace.s16),
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (var i = row * 3; i < row * 3 + 3; i++) ...[
                if (i % 3 > 0) const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: FormatChip(
                    label: formats[i].name.toUpperCase(),
                    selected: _format == formats[i],
                    showProBadge: !isPro && formats[i].isPro,
                    onTap: () async {
                      if (formats[i].isPro && !isPro) {
                        await ProGateSheet.show(
                          context,
                          feature: l10n.featureFormat(
                            formats[i].name.toUpperCase(),
                          ),
                          analyticsFeature: formats[i].name,
                          detail: formatDetail(l10n, formats[i]),
                          isFormat: true,
                        );
                        return;
                      }
                      setState(() => _format = formats[i]);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s10),
        ],
        if (!lossless)
          SegmentedControl<int>(
            items: [
              SegmentedItem(value: 128, label: l10n.qualityStandard),
              SegmentedItem(value: 256, label: l10n.qualityHigh),
              SegmentedItem(value: 320, label: l10n.qualityBest),
            ],
            value: _kbps,
            onChanged: (kbps) => setState(() => _kbps = kbps),
          ),
        const SizedBox(height: AppSpace.s20),
        PrimaryButton(
          label: l10n.save,
          onPressed: () async {
            await ref
                .read(preferencesProvider.notifier)
                .setDefaultFormat(_format, _kbps);
            ref
                .read(analyticsProvider)
                .preferencesChanged(
                  field: 'default_format',
                  value: _format.isLossless
                      ? _format.name
                      : '${_format.name}_$_kbps',
                );
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
