import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'theme_context.dart';
import 'tokens.dart';

/// Sheets stay phone-width in wide windows (iPhone Duo unfolded).
const sheetMaxWidth = 560.0;

class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
  }) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: AppLocalizations.of(context).dismiss,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.of(AppMotion.modalIn, reduce),
      pageBuilder: (dialogContext, animation, _) {
        return _SheetFrame(
          animation: animation,
          isDismissible: isDismissible,
          reduceMotion: reduce,
          child: builder(dialogContext),
        );
      },
      transitionBuilder: (_, _, _, child) => child,
    );
  }
}

class _SheetFrame extends StatefulWidget {
  const _SheetFrame({
    required this.animation,
    required this.isDismissible,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool isDismissible;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<_SheetFrame> {
  late final CurvedAnimation _scrim;
  late final CurvedAnimation _sheet;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _scrim = CurvedAnimation(parent: widget.animation, curve: Curves.easeOut);
    _sheet = CurvedAnimation(
      parent: widget.animation,
      curve: widget.reduceMotion ? Curves.easeOut : const SheetSpringCurve(),
    );
    _position = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_sheet);
  }

  @override
  void dispose() {
    _scrim.dispose();
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        FadeTransition(
          opacity: _scrim,
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
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: sheetMaxWidth),
            child: FadeTransition(
              opacity: widget.reduceMotion
                  ? _scrim
                  : const AlwaysStoppedAnimation(1),
              child: SlideTransition(
                position: widget.reduceMotion
                    ? const AlwaysStoppedAnimation(Offset.zero)
                    : _position,
                child: _SheetSurface(
                  isDismissible: widget.isDismissible,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.isDismissible, required this.child});

  final bool isDismissible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onVerticalDragEnd: isDismissible
          ? (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 400) {
                Navigator.of(context).pop();
              }
            }
          : null,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s24,
              AppSpace.s10,
              AppSpace.s24,
              AppSpace.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
