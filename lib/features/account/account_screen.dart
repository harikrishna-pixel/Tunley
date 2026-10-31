import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/account.dart';
import '../../core/account/account_api.dart';
import '../../core/design_system/design_system.dart';
import '../../core/rules/account_rules.dart';
import '../../l10n/app_localizations.dart';
import 'account_widgets.dart';

/// 51 Account: verify banner, invite code (+ random once), rewards, change
/// password, sign out, delete. Pro is tied to the Apple ID, not this.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(accountProvider.notifier).refresh().catchError((Object _) {}),
    );
  }

  Future<void> _guard(Future<void> Function() run, {String? done}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await run();
      if (mounted && done != null) TunelyToast.show(context, message: done);
    } on AccountException catch (e) {
      if (mounted) {
        TunelyToast.show(
          context,
          message: accountErrorText(l10n, e.error),
          tone: ToastTone.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _randomCode() async {
    final l10n = AppLocalizations.of(context);
    final ok = await AppAlert.show<bool>(
      context: context,
      title: l10n.accountRandomTitle,
      body: l10n.accountRandomBody,
      actions: [
        AlertAction(l10n.cancel, false),
        AlertAction(l10n.accountRandomConfirm, true),
      ],
    );
    if (ok == true) {
      await _guard(ref.read(accountProvider.notifier).useRandomCode);
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final ok = await AppAlert.show<bool>(
      context: context,
      title: l10n.accountSignOutTitle,
      body: l10n.accountSignOutBody,
      actions: [
        AlertAction(l10n.cancel, false),
        AlertAction(l10n.accountSignOut, true, tone: AlertTone.destructive),
      ],
    );
    if (ok != true) return;
    await ref.read(accountProvider.notifier).signOut();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final user = ref.watch(accountProvider).user;
    if (user == null) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(child: NavHeader(title: l10n.accountTitle)),
      );
    }

    Widget row(String label, {Widget? trailing, VoidCallback? onTap}) =>
        InkWell(
          onTap: _busy ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s20),
            child: Row(
              children: [
                Expanded(child: Text(label, style: text.body)),
                trailing ??
                    PhosphorIcon(
                      PhosphorIcons.caretRight(),
                      color: colors.text3,
                      size: 16,
                    ),
              ],
            ),
          ),
        );
    Widget group(List<Widget> rows) => AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.divider),
            rows[i],
          ],
        ],
      ),
    );

    return FormScaffold(
      header: NavHeader(title: l10n.accountTitle),
      content: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.s20),
          child: Row(
            children: [
              InitialsAvatar(user: user),
              const SizedBox(width: AppSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: text.navTitle,
                    ),
                    Text(
                      user.email,
                      style: text.body.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!user.verified) ...[
          const SizedBox(height: AppSpace.s16),
          Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: colors.warnSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.envelopeSimple(),
                  color: colors.warn,
                  size: 20,
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.verifyBannerBold,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: l10n.verifyBannerRest(user.email)),
                      ],
                    ),
                    style: text.caption.copyWith(color: colors.warn),
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    onTap: _busy
                        ? null
                        : () => _guard(
                            ref
                                .read(accountProvider.notifier)
                                .resendVerification,
                            done: l10n.verifySent,
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s14,
                        vertical: AppSpace.s10,
                      ),
                      child: Text(
                        l10n.verifyResend,
                        style: text.subhead.copyWith(
                          color: colors.warn,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.s20),
        SectionLabel(l10n.accountInviteRewards),
        group([
          Padding(
            padding: const EdgeInsets.all(AppSpace.s20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountYourCode,
                        style: text.caption.copyWith(color: colors.text2),
                      ),
                      Text(
                        user.referralCode,
                        style: text.navTitle.copyWith(letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _randomCode,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                  ),
                  child: Text(
                    l10n.accountRandomCode,
                    style: text.subhead.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          row(
            l10n.accountFreeEarned,
            trailing: Text(
              l10n.statDays(user.rewardDays),
              style: text.subhead.copyWith(
                color: colors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          row(
            l10n.accountInvite,
            onTap: () => context.push('/invite', extra: 'account'),
          ),
        ]),
        const SizedBox(height: AppSpace.s20),
        SectionLabel(l10n.accountSecurity),
        group([
          row(
            l10n.accountChangePassword,
            onTap: () => AppBottomSheet.show<void>(
              context: context,
              builder: (_) => const _ChangePasswordSheet(),
            ),
          ),
          row(l10n.accountSignOut, onTap: _signOut),
        ]),
        const SizedBox(height: AppSpace.s14),
        Text(
          l10n.accountProNote,
          style: text.caption.copyWith(color: colors.text2),
        ),
      ],
      footer: [
        _DangerButton(
          label: l10n.accountDelete,
          onPressed: _busy ? null : () => context.push('/account/delete'),
        ),
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: colors.danger),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: context.appText.button.copyWith(color: colors.danger),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  AccountError? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_current.text.isEmpty || !AccountRules.passwordStrong(_next.text)) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(accountProvider.notifier)
          .changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      TunelyToast.show(context, message: l10n.passwordChanged);
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.changePasswordTitle, style: context.appText.dialogTitle),
        const SizedBox(height: AppSpace.s16),
        if (_error != null) ...[
          InlineErrorBox(message: accountErrorText(l10n, _error!)),
          const SizedBox(height: AppSpace.s12),
        ],
        AppTextField(
          label: l10n.fieldCurrentPassword,
          controller: _current,
          obscure: true,
          error: _submitted && _current.text.isEmpty
              ? l10n.fieldRequired
              : null,
          autofillHints: const [AutofillHints.password],
        ),
        const SizedBox(height: AppSpace.s14),
        AppTextField(
          label: l10n.fieldNewPassword,
          controller: _next,
          obscure: true,
          error: _submitted
              ? fieldErrorText(l10n, AccountRules.password(_next.text))
              : null,
          hint: l10n.passwordRule,
          hintOk: AccountRules.passwordStrong(_next.text),
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.s20),
        PrimaryButton(label: l10n.save, onPressed: _busy ? null : _save),
      ],
    );
  }
}

/// 52 Delete account: password confirm, in-app (Apple 5.1.1(v)).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _password = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  AccountError? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_password.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountProvider.notifier).deleteAccount(_password.text);
      if (!mounted) return;
      TunelyToast.show(context, message: l10n.deleteDone);
      context.go('/settings');
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final user = ref.watch(accountProvider).user;
    Widget box(String title, List<String> lines, Color fg, Color bg) =>
        Container(
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: fg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: text.footnote.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.s6),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s4),
                  child: Text('•  $line', style: text.body),
                ),
            ],
          ),
        );
    return FormScaffold(
      header: const NavHeader(title: ''),
      content: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.dangerSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: PhosphorIcon(
              PhosphorIcons.trash(),
              color: colors.danger,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Semantics(
          header: true,
          child: Text(l10n.deleteTitle2, style: text.largeTitle),
        ),
        const SizedBox(height: AppSpace.s16),
        box(
          l10n.deleteGone,
          [
            if (user != null)
              l10n.deleteGoneAccount(
                '${user.firstName} ${user.lastName}',
                user.email,
              ),
            if (user != null) l10n.deleteGoneCode(user.referralCode),
            l10n.deleteGoneDays,
          ],
          colors.danger,
          colors.dangerSoft,
        ),
        const SizedBox(height: AppSpace.s16),
        box(
          l10n.deleteKept,
          [l10n.deleteKeptFiles, l10n.deleteKeptPro],
          colors.success,
          colors.successSoft,
        ),
        const SizedBox(height: AppSpace.s20),
        if (_error != null) ...[
          InlineErrorBox(message: accountErrorText(l10n, _error!)),
          const SizedBox(height: AppSpace.s12),
        ],
        AppTextField(
          label: l10n.deletePasswordLabel,
          controller: _password,
          obscure: true,
          error: _submitted && _password.text.isEmpty
              ? l10n.fieldRequired
              : null,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _delete(),
        ),
      ],
      footer: [
        Semantics(
          button: true,
          child: Material(
            color: colors.danger,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.button),
              onTap: _busy ? null : _delete,
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: Center(
                  child: Text(
                    l10n.accountDelete,
                    style: text.button.copyWith(color: colors.accentText),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        TextLinkButton(
          label: l10n.deleteKeep,
          muted: true,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
