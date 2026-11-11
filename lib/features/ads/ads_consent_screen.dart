import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/ads.dart';
import '../../app/monetization.dart';
import '../../app/state.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/library/usage_store.dart';
import '../../l10n/app_localizations.dart';
import '../paywall/paywall_screen.dart';

/// Consent order (`05` §12): Google's UMP form first where required (EEA,
/// UK, CH), then our 44 once ever, then the system ATT prompt. Free users only;
/// runs after onboarding and the first paywall, never during them.
Future<void> runAdsConsent(BuildContext context, WidgetRef ref) async {
  if (ref.read(isProProvider)) return;
  final usage = ref.read(usageStoreProvider);
  final engine = ref.read(audioEngineProvider);
  await ref.read(adsProvider.notifier).start();
  if (await usage.trackingPromptShown()) return;
  if (await engine.trackingStatus() != 'notDetermined') {
    await usage.markTrackingPromptShown();
    return;
  }
  if (!context.mounted) return;
  await usage.markTrackingPromptShown();
  if (!context.mounted) return;
  ref.read(analyticsProvider).trackingPromptShown();
  await context.push('/ads-consent');
}

class AdsConsentScreen extends ConsumerStatefulWidget {
  const AdsConsentScreen({super.key});

  @override
  ConsumerState<AdsConsentScreen> createState() => _AdsConsentScreenState();
}

class _AdsConsentScreenState extends ConsumerState<AdsConsentScreen> {
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    final status = await ref.read(audioEngineProvider).requestTracking();
    ref.read(analyticsProvider).trackingResult(status: status);
    if (mounted) context.pop();
  }

  Future<void> _seePro() async {
    ref.read(analyticsProvider).removeAdsTapped(screen: 'ads_consent');
    await openPaywall(context, PaywallSource.removeAds);
    // ATT is still asked: denial only means non-personalised ads.
    if (mounted && !ref.read(isProProvider)) await _continue();
    if (mounted && ref.read(isProProvider)) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    Widget bullet(IconData icon, String label) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: PhosphorIcon(icon, color: colors.link, size: 20),
          ),
          const SizedBox(width: AppSpace.s14),
          Expanded(
            child: Text(label, style: text.body.copyWith(color: colors.text2)),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen + AppSpace.s10,
                  AppSpace.s24,
                  AppSpace.screen + AppSpace.s10,
                  AppSpace.s24,
                ),
                children: [
                  const SizedBox(height: AppSpace.s24 * 3),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: colors.heroGradient,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.handHeart(),
                        color: colors.heroText,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s24),
                  Semantics(
                    header: true,
                    child: Text(l10n.adsConsentTitle, style: text.largeTitle),
                  ),
                  const SizedBox(height: AppSpace.s24),
                  bullet(PhosphorIcons.clock(), l10n.adsConsentBetweenTasks),
                  bullet(PhosphorIcons.shieldCheck(), l10n.adsConsentPrivate),
                  bullet(
                    PhosphorIcons.slidersHorizontal(),
                    l10n.adsConsentTracking,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                0,
                AppSpace.screen,
                AppSpace.s8,
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: l10n.continueAction,
                    onPressed: _busy ? null : _continue,
                  ),
                  const SizedBox(height: AppSpace.s4),
                  TextLinkButton(
                    label: l10n.adsConsentSeePro,
                    onPressed: _busy ? null : _seePro,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
