import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/account/account_api.dart';
import '../../core/design_system/design_system.dart';
import '../../core/rules/account_rules.dart';
import '../../l10n/app_localizations.dart';

String? fieldErrorText(AppLocalizations l10n, FieldError? error) =>
    switch (error) {
      null => null,
      FieldError.required => l10n.fieldRequired,
      FieldError.tooLong => l10n.fieldTooLong,
      FieldError.invalidEmail => l10n.fieldEmailInvalid,
      FieldError.weakPassword => l10n.fieldPasswordWeak,
    };

/// Inline message for a failed call (`12` §8). Form data is never cleared.
String accountErrorText(AppLocalizations l10n, AccountError error) =>
    switch (error) {
      AccountError.offline => l10n.accountOffline,
      AccountError.invalidCredentials => l10n.signInError,
      AccountError.rateLimited => l10n.signInLocked,
      AccountError.emailExists => l10n.emailExists,
      AccountError.wrongPassword => l10n.changePasswordWrong,
      AccountError.invalidCode ||
      AccountError.deviceUsed ||
      AccountError.selfReferral => l10n.redeemInvalid,
      _ => l10n.accountServerError,
    };

class InlineErrorBox extends StatelessWidget {
  const InlineErrorBox({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s14),
        decoration: BoxDecoration(
          color: colors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.status),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(
              PhosphorIcons.warningCircle(),
              color: colors.danger,
              size: 20,
            ),
            const SizedBox(width: AppSpace.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: text.subhead.copyWith(color: colors.danger),
                  ),
                  ?action,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Give 1 week · Get 1 week" banner on 46 / 47.
// TODO(question #26): final invite artwork; brand gradient until then.
class InviteBanner extends StatelessWidget {
  const InviteBanner({super.key, this.height = 190});

  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Container(
        height: height,
        decoration: BoxDecoration(gradient: colors.heroGradient),
        child: Stack(
          children: [
            Center(
              child: ExcludeSemantics(
                child: PhosphorIcon(
                  PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                  color: const Color(0x40FFFFFF),
                  size: height * 0.55,
                ),
              ),
            ),
            Positioned(
              left: AppSpace.s16,
              bottom: AppSpace.s16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s14,
                  vertical: AppSpace.s8,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.proChip),
                ),
                child: Text(
                  l10n.inviteBadge,
                  style: text.caption.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.user, this.size = 64});

  final AccountUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
        child: Text(
          user.initials,
          style: context.appText.subhead.copyWith(
            color: colors.accentText,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );
  }
}

/// Screen padding + content + bottom actions, scrolling at large text sizes.
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.header,
    required this.content,
    required this.footer,
  });

  final Widget header;
  final List<Widget> content;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.s24,
                ),
                children: content,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.s8,
                AppSpace.screen,
                AppSpace.s8,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: footer),
            ),
          ],
        ),
      ),
    );
  }
}
