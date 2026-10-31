import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';
import 'tokens.dart';

/// Dialogs keep a phone width in wide windows.
const dialogMaxWidth = 440.0;

class AppDialog {
  AppDialog._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    EdgeInsets padding = const EdgeInsets.all(AppSpace.s24),
  }) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: AppLocalizations.of(context).dismiss,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.of(AppMotion.dialog, reduce),
      pageBuilder: (dialogContext, animation, _) {
        return _DialogFrame(
          animation: animation,
          isDismissible: isDismissible,
          reduceMotion: reduce,
          padding: padding,
          child: builder(dialogContext),
        );
      },
      transitionBuilder: (_, _, _, child) => child,
    );
  }
}

class _DialogFrame extends StatefulWidget {
  const _DialogFrame({
    required this.animation,
    required this.isDismissible,
    required this.reduceMotion,
    required this.padding,
    required this.child,
  });

  final Animation<double> animation;
  final bool isDismissible;
  final bool reduceMotion;
  final EdgeInsets padding;
  final Widget child;

  @override
  State<_DialogFrame> createState() => _DialogFrameState();
}

class _DialogFrameState extends State<_DialogFrame> {
  late final CurvedAnimation _curved;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _curved = CurvedAnimation(parent: widget.animation, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(_curved);
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = widget.reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : _scale;
    return Stack(
      children: [
        FadeTransition(
          opacity: _curved,
          child: GestureDetector(
            onTap: widget.isDismissible
                ? () => Navigator.of(context).pop()
                : null,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppBlur.overlay,
                sigmaY: AppBlur.overlay,
              ),
              child: ColoredBox(
                color: colors.scrim,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: dialogMaxWidth),
              child: FadeTransition(
                opacity: _curved,
                child: ScaleTransition(
                  scale: scale,
                  child: Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.dialog),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum AlertTone { primary, destructive }

class AlertAction<T> {
  const AlertAction(this.label, this.value, {this.tone = AlertTone.primary});

  final String label;
  final T value;
  final AlertTone tone;
}

/// iOS-style confirmation: title, body and full-width action rows.
abstract final class AppAlert {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String body,
    required List<AlertAction<T>> actions,
  }) {
    return AppDialog.show<T>(
      context: context,
      padding: EdgeInsets.zero,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        final text = dialogContext.appText;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s24,
                AppSpace.s24,
                AppSpace.s24,
                AppSpace.s20,
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.dialogTitle,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: text.body.copyWith(color: colors.text2),
                  ),
                ],
              ),
            ),
            for (final action in actions) ...[
              Divider(height: 1, thickness: 1, color: colors.divider),
              InkWell(
                onTap: () => Navigator.of(dialogContext).pop(action.value),
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: Text(
                      action.label,
                      style: text.button.copyWith(
                        color: action.tone == AlertTone.destructive
                            ? colors.danger
                            : colors.link,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
