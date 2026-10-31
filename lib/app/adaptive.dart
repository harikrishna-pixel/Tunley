import 'package:flutter/widgets.dart';

import '../core/design_system/theme_context.dart';

enum NavEdge { left, right }

/// Layout decisions from the window size, never from the device, idiom or
/// orientation (iPhone Duo resizes the app when it folds or unfolds, and its
/// inner display ignores the portrait lock).
abstract final class AdaptiveLayout {
  /// Regular width, like an iPad: side navigation and centred content.
  static const wideMinWidth = 600.0;

  /// Readable column for screens designed for a phone width.
  static const contentMaxWidth = 640.0;

  static bool isWide(Size size) => size.width >= wideMinWidth;

  /// The vertical tab rail sits on the edge with the larger safe-area inset
  /// (on iPhone Duo the system strip below the status bar), else leading.
  static NavEdge navEdge(EdgeInsets padding, TextDirection direction) {
    if (padding.right > padding.left) return NavEdge.right;
    if (padding.left > padding.right) return NavEdge.left;
    return direction == TextDirection.rtl ? NavEdge.right : NavEdge.left;
  }
}

/// Centres a phone-width screen in a wide window. The background still fills
/// the window, so nothing looks letterboxed.
class AdaptivePage extends StatelessWidget {
  const AdaptivePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= AdaptiveLayout.contentMaxWidth) {
          return child;
        }
        return ColoredBox(
          color: context.colors.bg,
          child: Center(
            child: SizedBox(
              width: AdaptiveLayout.contentMaxWidth,
              // Centred away from the edges: side insets no longer apply.
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
