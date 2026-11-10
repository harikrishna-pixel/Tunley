import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/account.dart';
import '../../app/state.dart';
import '../../core/account/account_api.dart';
import '../../core/design_system/design_system.dart';
import '../../core/rules/account_rules.dart';
import '../../l10n/app_localizations.dart';
import 'account_widgets.dart';

class RedeemArgs {
  const RedeemArgs({this.code, this.fromLink = false});

  final String? code;
  final bool fromLink;
}

/// 53 Redeem invite code (+ 53b success, 53c invalid). No login, ever.
class RedeemScreen extends ConsumerStatefulWidget {
  const RedeemScreen({super.key, this.args = const RedeemArgs()});

  final RedeemArgs args;

  @override
  ConsumerState<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends ConsumerState<RedeemScreen> {
  late final _code = TextEditingController(text: widget.args.code ?? '');
  bool _busy = false;
  AccountError? _error;
  RedeemResult? _result;
  bool _valid = false;
  DateTime? _maxLengthToastAt;

  static const _maxCodeLength = 10;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _toastMaxLength() {
    final now = DateTime.now();
    final last = _maxLengthToastAt;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _maxLengthToastAt = now;
    if (!mounted) return;
    TunelyToast.show(
      context,
      message: AppLocalizations.of(context).redeemCodeMaxLength,
    );
  }

  Future<void> _apply() async {
    setState(() {
      _busy = true;
      _error = null;
      _valid = false;
    });
    if (!ReferralCode.looksValid(_code.text)) {
      setState(() {
        _busy = false;
        _error = AccountError.invalidCode;
      });
      return;
    }
    try {
      final result = await ref
          .read(referralProvider.notifier)
          .redeem(
            _code.text,
            source: widget.args.fromLink
                ? RedeemSource.deepLink
                : RedeemSource.manual,
          );
      if (!mounted) return;
      setState(() => _valid = true);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) setState(() => _result = result);
    } on AccountException catch (e) {
      if (mounted) {
        setState(() {
          // Treat redeem failures as invalid so the user sees a clear
          // "Invalid invite code" instead of a generic server message.
          _error = switch (e.error) {
            AccountError.offline => AccountError.offline,
            AccountError.rateLimited => AccountError.rateLimited,
            _ => AccountError.invalidCode,
          };
        });
      }
    } on Object {
      if (mounted) setState(() => _error = AccountError.invalidCode);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _close() =>
      Navigator.of(context).canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final header = NavHeader(
      title: '',
      leading: NavLeading.close,
      onLeading: _close,
    );
    final result = _result;
    if (result != null) {
      final name = result.inviterFirstName.isEmpty
          ? l10n.redeemFriend
          : result.inviterFirstName;
      final already = result.alreadyPro || ref.read(isProProvider);
      return FormScaffold(
        header: header,
        content: [
          const SizedBox(height: AppSpace.s24 * 4),
          Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: colors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.hero),
              ),
              child: PhosphorIcon(
                PhosphorIcons.crown(PhosphorIconsStyle.fill),
                color: colors.gold,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s20),
          Semantics(
            header: true,
            child: Text(
              l10n.redeemSuccessTitle,
              textAlign: TextAlign.center,
              style: text.largeTitle,
            ),
          ),
          const SizedBox(height: AppSpace.s10),
          Text(
            already
                ? l10n.redeemAlreadyPro
                : l10n.redeemSuccessBody(
                    name,
                    DateFormat.yMMMd(l10n.localeName).format(result.proUntil),
                  ),
            textAlign: TextAlign.center,
            style: text.body.copyWith(color: colors.text2),
          ),
          if (!already) ...[
            const SizedBox(height: AppSpace.s16),
            Container(
              padding: const EdgeInsets.all(AppSpace.s16),
              decoration: BoxDecoration(
                color: colors.successSoft,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Text(
                l10n.redeemSuccessHint(name),
                textAlign: TextAlign.center,
                style: text.subhead.copyWith(color: colors.success),
              ),
            ),
          ],
        ],
        footer: [
          PrimaryButton(
            label: l10n.redeemMakeFile,
            onPressed: () => context.go('/home'),
          ),
        ],
      );
    }

    return FormScaffold(
      header: header,
      content: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: PhosphorIcon(
              PhosphorIcons.gift(),
              color: colors.accentOnSoft,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Semantics(
          header: true,
          child: Text(
            l10n.redeemTitle,
            textAlign: TextAlign.center,
            style: text.largeTitle,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          l10n.redeemBody,
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.text2),
        ),
        const SizedBox(height: AppSpace.s20),
        AppTextField(
          label: l10n.redeemLabel,
          controller: _code,
          large: true,
          error: _error == AccountError.invalidCode ? '' : null,
          hint: widget.args.fromLink && _error == null
              ? l10n.redeemFromLink
              : null,
          hintOk: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            _MaxLengthToastFormatter(
              maxLength: _maxCodeLength,
              onExceeded: _toastMaxLength,
            ),
          ],
          onChanged: (_) {
            if (_error != null || _valid) {
              setState(() {
                _error = null;
                _valid = false;
              });
            }
          },
          onSubmitted: (_) => _apply(),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.s12),
          InlineErrorBox(
            message: _error == AccountError.invalidCode
                ? l10n.redeemInvalidCode
                : accountErrorText(l10n, _error!),
          ),
        ] else if (_valid) ...[
          const SizedBox(height: AppSpace.s12),
          StatusBox(message: l10n.redeemValidCode),
        ],
      ],
      footer: [
        PrimaryButton(label: l10n.redeemCta, onPressed: _busy ? null : _apply),
        const SizedBox(height: AppSpace.s4),
        TextLinkButton(label: l10n.redeemSkip, muted: true, onPressed: _close),
      ],
    );
  }
}

/// Keeps the 10-character cap and notifies when the user tries to go past it.
class _MaxLengthToastFormatter extends TextInputFormatter {
  _MaxLengthToastFormatter({
    required this.maxLength,
    required this.onExceeded,
  });

  final int maxLength;
  final VoidCallback onExceeded;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= maxLength) return newValue;
    onExceeded();
    if (oldValue.text.length >= maxLength) {
      return TextEditingValue(
        text: oldValue.text.substring(0, maxLength),
        selection: TextSelection.collapsed(offset: maxLength),
      );
    }
    return TextEditingValue(
      text: newValue.text.substring(0, maxLength),
      selection: TextSelection.collapsed(offset: maxLength),
    );
  }
}
