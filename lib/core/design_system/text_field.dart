import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';
import 'tokens.dart';

/// Labelled form field (48–53). Errors show under the field, never only in a
/// toast (`12` §2).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.hint,
    this.hintOk = false,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.large = false,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? error;

  /// Line under the field when there is no error (password rule, "Added
  /// from your friend's link").
  final String? hint;

  /// Shows [hint] in success colour with a check.
  final bool hintOk;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  /// Bigger, letter-spaced text (invite code).
  final bool large;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.appText;
    final error = widget.error;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: BorderSide(color: color, width: width),
    );
    final style = widget.large
        ? text.navTitle.copyWith(letterSpacing: 3, fontWeight: FontWeight.w800)
        : text.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: text.caption.copyWith(
            color: colors.text2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          autocorrect: false,
          enableSuggestions: !widget.obscure,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          style: style.copyWith(color: colors.text),
          cursorColor: colors.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s16,
            ),
            enabledBorder: border(
              error == null ? colors.border : colors.danger,
              error == null ? 1 : 2,
            ),
            focusedBorder: border(
              error == null ? colors.accent : colors.danger,
              2,
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? l10n.showPassword : l10n.hidePassword,
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: PhosphorIcon(
                      _hidden ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                      color: colors.text2,
                      size: 22,
                    ),
                  )
                : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpace.s6),
          Text(error, style: text.caption.copyWith(color: colors.danger)),
        ] else if (widget.hint != null) ...[
          const SizedBox(height: AppSpace.s6),
          Row(
            children: [
              if (widget.hintOk) ...[
                PhosphorIcon(
                  PhosphorIcons.check(PhosphorIconsStyle.bold),
                  color: colors.success,
                  size: 14,
                ),
                const SizedBox(width: AppSpace.s6),
              ],
              Expanded(
                child: Text(
                  widget.hint!,
                  style: text.caption.copyWith(
                    color: widget.hintOk ? colors.success : colors.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
