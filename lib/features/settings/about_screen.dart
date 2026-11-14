import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/config.dart';
import '../../app/state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_screen.dart';
import 'settings_screen.dart';

/// Settings › About Us — brand, version, privacy / terms / contact / share / rate.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String url) async {
    final opened = await ref.read(audioEngineProvider).openUrl(url);
    if (!context.mounted) return;
    if (!opened) {
      TunelyToast.show(
        context,
        message: AppLocalizations.of(context).couldNotOpen,
      );
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final url = ref.read(appConfigProvider).appStoreUrl ?? '';
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: l10n.aboutShareText(url).trim(),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  /// In-app App Store page (SKStoreProductViewController), same as More apps.
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
    final version = ref.watch(appInfoProvider).value?.version ?? '';

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(
              title: l10n.aboutTitle,
              onLeading: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s16,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: colors.heroGradient,
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                        boxShadow: colors.shadow,
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.filmSlate(PhosphorIconsStyle.fill),
                        color: colors.heroText,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  Text(
                    'Tunely',
                    textAlign: TextAlign.center,
                    style: text.largeTitle,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    l10n.aboutTagline,
                    textAlign: TextAlign.center,
                    style: text.body.copyWith(color: colors.text2),
                  ),
                  if (version.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.s14),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s14,
                          vertical: AppSpace.s6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          l10n.aboutVersion(version),
                          style: text.caption.copyWith(
                            color: colors.accentOnSoft,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.s24),
                  // Order per Sabitha reference: legal/contact first, Share & Rate last.
                  ListGroup(
                    children: [
                      SettingsRow(
                        icon: PhosphorIcons.shieldCheck(),
                        label: l10n.aboutPrivacy,
                        onTap: () => _open(context, ref, privacyUrl),
                      ),
                      SettingsRow(
                        icon: PhosphorIcons.fileText(),
                        label: l10n.aboutTerms,
                        onTap: () => _open(context, ref, termsUrl),
                      ),
                      SettingsRow(
                        icon: PhosphorIcons.envelopeSimple(),
                        label: l10n.aboutContact,
                        onTap: () => contactSupport(
                          context,
                          ref,
                          screen: 'about',
                        ),
                      ),
                      SettingsRow(
                        icon: PhosphorIcons.shareNetwork(),
                        label: l10n.aboutShareApp,
                        onTap: () => _share(context, ref),
                      ),
                      SettingsRow(
                        icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                        label: l10n.aboutRateUs,
                        onTap: () => _rate(ref),
                      ),
                    ],
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
