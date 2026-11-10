import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/account.dart';
import '../../core/account/account_api.dart';
import '../../core/design_system/design_system.dart';
import '../../core/engine/audio_engine.dart';
import '../../core/rules/account_rules.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import 'account_widgets.dart';

Widget _title(BuildContext context, String title, [String? subtitle]) {
  final text = context.appText;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(header: true, child: Text(title, style: text.largeTitle)),
      if (subtitle != null && subtitle.isNotEmpty) ...[
        const SizedBox(height: AppSpace.s6),
        Text(subtitle, style: text.body.copyWith(color: context.colors.text2)),
      ],
      const SizedBox(height: AppSpace.s20),
    ],
  );
}

Widget _footerLink(
  BuildContext context, {
  required String prefix,
  required String link,
  required VoidCallback onTap,
}) {
  final colors = context.colors;
  final text = context.appText;
  return Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
        child: Text.rich(
          TextSpan(
            text: prefix,
            style: text.subhead.copyWith(color: colors.text2),
            children: [
              TextSpan(
                text: link,
                style: text.subhead.copyWith(
                  color: colors.link,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

/// 48 Create account. Only reached from Invite friends.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  AccountError? _error;

  /// Random tail for the live preview; the server makes the real code.
  final String _tail = ReferralCode.suggest('').substring(4);

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _preview {
    final name = ReferralCode.namePart(_first.text);
    return name.length < 2 ? 'TUNE$_tail' : '$name${_tail.substring(0, 2)}';
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    final valid = [
      AccountRules.name(_first.text),
      AccountRules.name(_last.text),
      AccountRules.email(_email.text),
      AccountRules.password(_password.text),
    ].every((e) => e == null);
    if (!valid) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(accountProvider.notifier)
          .signUp(
            firstName: _first.text,
            lastName: _last.text,
            email: _email.text,
            password: _password.text,
          );
      if (mounted) context.pop(true);
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.error);
    } on Object {
      if (mounted) setState(() => _error = AccountError.server);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    String? err(FieldError? e) => _submitted ? fieldErrorText(l10n, e) : null;
    final strong = AccountRules.passwordStrong(_password.text);
    final engine = ref.read(audioEngineProvider);

    return AutofillGroup(
      child: FormScaffold(
        header: const NavHeader(title: ''),
        content: [
          _title(context, l10n.signUpTitle, l10n.signUpSubtitle),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: l10n.fieldFirstName,
                  controller: _first,
                  error: err(AccountRules.name(_first.text)),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: AppTextField(
                  label: l10n.fieldLastName,
                  controller: _last,
                  error: err(AccountRules.name(_last.text)),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            label: l10n.fieldEmail,
            controller: _email,
            error: err(AccountRules.email(_email.text)),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            label: l10n.fieldPassword,
            controller: _password,
            obscure: true,
            error: err(AccountRules.password(_password.text)),
            hint: l10n.passwordRule,
            hintOk: strong,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpace.s16),
          Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.signUpCodePreview,
                  style: text.caption.copyWith(
                    color: colors.accentOnSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _preview,
                  style: text.navTitle.copyWith(letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
        footer: [
          // Keep account errors above the CTA so they stay on-screen.
          if (_error != null && _error != AccountError.emailExists) ...[
            InlineErrorBox(message: accountErrorText(l10n, _error!)),
            const SizedBox(height: AppSpace.s12),
          ],
          if (_error == AccountError.emailExists) ...[
            InlineErrorBox(
              message: l10n.emailExists,
              action: TextLinkButton(
                label: l10n.emailExistsSignIn,
                onPressed: () => context.pushReplacement('/account/sign-in'),
              ),
            ),
            const SizedBox(height: AppSpace.s12),
          ],
          PrimaryButton(
            label: l10n.signUpCta,
            onPressed: _busy ? null : _submit,
          ),
          const SizedBox(height: AppSpace.s10),
          Text.rich(
            TextSpan(
              text: l10n.signUpTermsPrefix,
              style: text.footnote.copyWith(color: colors.text2),
              children: [
                TextSpan(
                  text: l10n.termsLink,
                  style: TextStyle(
                    color: colors.link,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => engine.openUrl(termsUrl),
                ),
                TextSpan(text: l10n.signUpTermsAnd),
                TextSpan(
                  text: l10n.privacyLink,
                  style: TextStyle(
                    color: colors.link,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => engine.openUrl(privacyUrl),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          _footerLink(
            context,
            prefix: l10n.signUpHaveAccount,
            link: l10n.signInLink,
            onTap: () => context.pushReplacement('/account/sign-in'),
          ),
        ],
      ),
    );
  }
}

/// 49 Sign in (+ 49b one generic error, no hint which field is wrong).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  AccountError? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (AccountRules.email(_email.text) != null || _password.text.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(accountProvider.notifier)
          .logIn(email: _email.text, password: _password.text);
      if (mounted) context.pop(true);
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.error);
    } on Object {
      if (mounted) setState(() => _error = AccountError.server);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wrong = _error == AccountError.invalidCredentials;
    return FormScaffold(
      header: const NavHeader(title: ''),
      content: [
        _title(context, l10n.signInTitle, l10n.signInSubtitle),
        if (_error != null) ...[
          InlineErrorBox(message: accountErrorText(l10n, _error!)),
          const SizedBox(height: AppSpace.s16),
        ],
        AppTextField(
          label: l10n.fieldEmail,
          controller: _email,
          error: _submitted
              ? fieldErrorText(l10n, AccountRules.email(_email.text))
              : null,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: AppSpace.s16),
        AppTextField(
          label: l10n.fieldPassword,
          controller: _password,
          obscure: true,
          error: _submitted && _password.text.isEmpty
              ? l10n.fieldRequired
              : wrong
              ? ''
              : null,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextLinkButton(
            label: l10n.forgotPassword,
            onPressed: () =>
                context.push('/account/reset', extra: _email.text.trim()),
          ),
        ),
      ],
      footer: [
        PrimaryButton(label: l10n.signInCta, onPressed: _busy ? null : _submit),
        _footerLink(
          context,
          prefix: l10n.signInNew,
          link: l10n.signInCreate,
          onTap: () => context.pushReplacement('/account/sign-up'),
        ),
      ],
    );
  }
}

/// 50 Reset password (+ 50b "Check your email", no account enumeration,
/// resend after 60 s).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email = ''});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  bool _submitted = false;
  bool _busy = false;
  bool _sent = false;
  AccountError? _error;
  DateTime? _sentAt;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    _email.dispose();
    super.dispose();
  }

  Duration get _wait {
    final at = _sentAt;
    if (at == null) return Duration.zero;
    final left = AccountRules.resendCooldown - DateTime.now().difference(at);
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> _send() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (AccountRules.email(_email.text) != null) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountProvider.notifier).forgot(_email.text);
      _sentAt = DateTime.now();
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_wait == Duration.zero) _tick?.cancel();
      });
      if (mounted) setState(() => _sent = true);
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
    if (_sent) {
      final wait = _wait;
      final time =
          '${wait.inMinutes}:${(wait.inSeconds % 60).toString().padLeft(2, '0')}';
      return FormScaffold(
        header: const NavHeader(title: ''),
        content: [
          const SizedBox(height: AppSpace.s24 * 4),
          Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.successSoft,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                PhosphorIcons.envelopeSimple(),
                color: colors.success,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s20),
          Semantics(
            header: true,
            child: Text(
              l10n.resetSentTitle,
              textAlign: TextAlign.center,
              style: text.largeTitle,
            ),
          ),
          const SizedBox(height: AppSpace.s10),
          Text.rich(
            TextSpan(
              text: l10n.resetSentPrefix,
              children: [
                TextSpan(
                  text: _email.text.trim(),
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: l10n.resetSentSuffix),
              ],
            ),
            textAlign: TextAlign.center,
            style: text.body.copyWith(color: colors.text2),
          ),
        ],
        footer: [
          PrimaryButton(label: l10n.resetBack, onPressed: () => context.pop()),
          const SizedBox(height: AppSpace.s4),
          TextLinkButton(
            label: wait == Duration.zero
                ? l10n.resetResend
                : l10n.resetResendIn(time),
            muted: true,
            onPressed: wait == Duration.zero && !_busy ? _send : null,
          ),
        ],
      );
    }
    return FormScaffold(
      header: const NavHeader(title: ''),
      content: [
        _title(context, l10n.resetTitle, l10n.resetBody),
        if (_error != null) ...[
          InlineErrorBox(message: accountErrorText(l10n, _error!)),
          const SizedBox(height: AppSpace.s16),
        ],
        AppTextField(
          label: l10n.fieldEmail,
          controller: _email,
          error: _submitted
              ? fieldErrorText(l10n, AccountRules.email(_email.text))
              : null,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _send(),
        ),
      ],
      footer: [
        PrimaryButton(label: l10n.resetCta, onPressed: _busy ? null : _send),
      ],
    );
  }
}
