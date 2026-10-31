import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/account.dart';
import '../../app/config.dart';
import '../../core/account/account_api.dart';
import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';
import '../../core/design_system/design_system.dart';
import '../../core/rules/account_rules.dart';
import '../../l10n/app_localizations.dart';
import '../common/share_tracking.dart';
import 'account_widgets.dart';

/// Invite friends: 46 (signed out, explains before any form) or 47.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, this.source = 'settings'});

  /// `invite_entry_opened.source`: settings · account.
  final String source;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  @override
  void initState() {
    super.initState();
    final signedIn = ref.read(accountProvider).signedIn;
    ref
        .read(analyticsProvider)
        .inviteEntryOpened(source: widget.source, signedIn: signedIn);
    if (signedIn) {
      unawaited(
        ref.read(accountProvider.notifier).refreshStats().catchError((_) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final user = account.user;
    return user == null
        ? const _SignedOut()
        : _SignedIn(user: user, stats: account.stats);
  }
}

class _SignedOut extends ConsumerWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final domain = ref.watch(appConfigProvider).referral.inviteDomain;
    Widget step(int n, String label) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: text.footnote.copyWith(
                color: colors.accentOnSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(label, style: text.body),
            ),
          ),
        ],
      ),
    );
    return FormScaffold(
      header: NavHeader(
        title: '',
        leading: NavLeading.none,
        trailing: _CloseButton(onTap: () => context.pop()),
      ),
      content: [
        const InviteBanner(),
        const SizedBox(height: AppSpace.s20),
        Semantics(
          header: true,
          child: Text(l10n.inviteTitle, style: text.largeTitle),
        ),
        const SizedBox(height: AppSpace.s16),
        step(1, l10n.inviteStep1),
        step(2, l10n.inviteStep2),
        step(3, l10n.inviteStep3),
        const SizedBox(height: AppSpace.s8),
        Container(
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              PhosphorIcon(PhosphorIcons.lock(), color: colors.text2, size: 20),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Text(
                  '$domain/i/••••••',
                  style: text.body.copyWith(
                    color: colors.text2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l10n.inviteYourLink,
                style: text.footnote.copyWith(color: colors.text2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.shieldCheck(),
              color: colors.success,
              size: 18,
            ),
            const SizedBox(width: AppSpace.s10),
            Expanded(
              child: Text(
                l10n.invitePrivacy,
                style: text.caption.copyWith(color: colors.text2),
              ),
            ),
          ],
        ),
      ],
      footer: [
        PrimaryButton(
          label: l10n.inviteCreateAccount,
          onPressed: () => context.push('/account/sign-up'),
        ),
        const SizedBox(height: AppSpace.s4),
        TextLinkButton(
          label: l10n.inviteHaveAccount,
          onPressed: () => context.push('/account/sign-in'),
        ),
      ],
    );
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.user, required this.stats});

  final AccountUser user;
  final ReferralStats? stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final domain = ref.watch(appConfigProvider).referral.inviteDomain;
    final link = ReferralCode.link(domain, user.referralCode);
    final shownLink = '$domain/i/${user.referralCode}';
    final s = stats ?? ReferralStats.empty;

    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: text.navTitle),
            Text(label, style: text.footnote.copyWith(color: colors.text2)),
          ],
        ),
      ),
    );

    Future<void> share() async {
      final result = await SharePlus.instance.share(
        ShareParams(text: l10n.inviteShareText(link)),
      );
      final target = shareTarget(result);
      if (target != null) {
        ref
            .read(analyticsProvider)
            .inviteLinkShared(channel: target == 'unknown' ? null : target);
      }
    }

    return FormScaffold(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.s8,
          AppSpace.s8,
          AppSpace.s8,
        ),
        child: Row(
          children: [
            InitialsAvatar(user: user, size: 32),
            const SizedBox(width: AppSpace.s10),
            Expanded(
              child: Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.subhead.copyWith(color: colors.text2),
              ),
            ),
            _CloseButton(onTap: () => context.pop()),
          ],
        ),
      ),
      content: [
        const InviteBanner(height: 220),
        const SizedBox(height: AppSpace.s20),
        Semantics(
          header: true,
          child: Text(l10n.inviteTitle, style: text.largeTitle),
        ),
        const SizedBox(height: AppSpace.s10),
        Text(
          l10n.inviteSignedInBody,
          style: text.body.copyWith(color: colors.text2),
        ),
        const SizedBox(height: AppSpace.s16),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s20,
            AppSpace.s10,
            AppSpace.s10,
            AppSpace.s10,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shownLink,
                      style: text.subhead.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      l10n.inviteCodeLine(user.referralCode),
                      style: text.caption.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
              Material(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (context.mounted) {
                      TunelyToast.show(context, message: l10n.linkCopiedInvite);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s20,
                      vertical: AppSpace.s14,
                    ),
                    child: Text(
                      l10n.copy,
                      style: text.subhead.copyWith(
                        color: colors.accentOnSoft,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              stat('${s.joined}', l10n.statFriendsJoined),
              const SizedBox(width: AppSpace.s10),
              stat(l10n.statDays(s.earnedDays), l10n.statProEarned),
              const SizedBox(width: AppSpace.s10),
              stat('${s.pending}', l10n.statPending),
            ],
          ),
        ),
        if (s.capReached) ...[
          const SizedBox(height: AppSpace.s12),
          StatusBox(message: l10n.inviteCapReached, tone: StatusTone.info),
        ],
      ],
      footer: [
        PrimaryButton(
          label: l10n.inviteShare,
          icon: PhosphorIcons.export(),
          onPressed: share,
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.close,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: PhosphorIcon(
        PhosphorIcons.x(),
        color: context.colors.text,
        size: 24,
      ),
    );
  }
}
