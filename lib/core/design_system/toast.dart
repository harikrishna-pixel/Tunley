import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'theme_context.dart';
import 'sheet.dart';
import 'tokens.dart';

enum ToastTone { success, info, warning, error }

/// One toast at a time. Information only: no decisions.
class TunelyToast {
  TunelyToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static final _key = GlobalKey<_ToastViewState>();

  static void show(
    BuildContext context, {
    required String message,
    ToastTone tone = ToastTone.success,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.colors;
    final iconBackground = switch (tone) {
      ToastTone.success => colors.success,
      ToastTone.info => colors.accent,
      ToastTone.warning => colors.warn,
      ToastTone.error => colors.danger,
    };
    final toneIcon =
        icon ??
        switch (tone) {
          ToastTone.success => PhosphorIcons.check(PhosphorIconsStyle.bold),
          ToastTone.info => PhosphorIcons.info(PhosphorIconsStyle.bold),
          ToastTone.warning => PhosphorIcons.warning(PhosphorIconsStyle.bold),
          ToastTone.error => PhosphorIcons.x(PhosphorIconsStyle.bold),
        };
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final hold = Duration(seconds: actionLabel == null ? 3 : 5);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _ToastView(
          key: _key,
          message: message,
          icon: toneIcon,
          iconBackground: iconBackground,
          actionLabel: actionLabel,
          reduceMotion: reduce,
          onAction: onAction == null
              ? null
              : () {
                  dismiss();
                  onAction();
                },
          onDismissed: () {
            if (_entry == entry) {
              entry.remove();
              _entry = null;
            }
          },
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(hold, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _key.currentState?.startExit();
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    super.key,
    required this.message,
    required this.icon,
    required this.iconBackground,
    required this.actionLabel,
    required this.reduceMotion,
    required this.onAction,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final Color iconBackground;
  final String? actionLabel;
  final bool reduceMotion;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.of(AppMotion.toastIn, widget.reduceMotion),
      reverseDuration: AppMotion.of(AppMotion.toastOut, widget.reduceMotion),
    )..forward();
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  void startExit() {
    if (!mounted || _controller.status == AnimationStatus.reverse) {
      return;
    }
    _controller.reverse().whenComplete(widget.onDismissed);
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: sheetMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.s8,
              AppSpace.screen,
              0,
            ),
            child: FadeTransition(
              opacity: _curved,
              child: SlideTransition(
                position: widget.reduceMotion
                    ? const AlwaysStoppedAnimation(Offset.zero)
                    : Tween<Offset>(
                        begin: const Offset(0, -0.4),
                        end: Offset.zero,
                      ).animate(_curved),
                child: Semantics(
                  liveRegion: true,
                  child: Material(
                    color: colors.toast,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s14,
                        vertical: AppSpace.s12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: widget.iconBackground,
                              shape: BoxShape.circle,
                            ),
                            child: PhosphorIcon(
                              widget.icon,
                              size: 16,
                              color: colors.heroText,
                            ),
                          ),
                          const SizedBox(width: AppSpace.s12),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: context.appText.subhead.copyWith(
                                color: colors.heroText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.actionLabel != null)
                            TextButton(
                              onPressed: widget.onAction,
                              child: Text(
                                widget.actionLabel!,
                                style: context.appText.subhead.copyWith(
                                  color: colors.toastAction,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
