import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/tokens.dart';
import 'adaptive.dart';

/// Runs [work] once the current route has finished animating in, so heavy
/// work never competes with a transition (`04` › Smoothness rules).
void afterRouteTransition(BuildContext context, VoidCallback work) {
  final animation = ModalRoute.of(context)?.animation;
  if (animation == null || animation.isCompleted) {
    WidgetsBinding.instance.addPostFrameCallback((_) => work());
    return;
  }
  late AnimationStatusListener listener;
  listener = (status) {
    if (status == AnimationStatus.completed) {
      animation.removeStatusListener(listener);
      work();
    }
  };
  animation.addStatusListener(listener);
}

/// Shared route transitions from `04` › Screen transitions.
///
/// Push uses [CupertinoPageRoute] so the left-edge swipe-back gesture works.
/// [CustomTransitionPage] cannot host that gesture. Every other presentation
/// is a [CustomTransitionPage].
abstract final class AppTransitions {
  static Page<T> push<T>({
    required LocalKey key,
    required Widget child,
    required bool reduceMotion,
  }) {
    return _PushPage<T>(
      key: key,
      reduceMotion: reduceMotion,
      child: AdaptivePage(child: child),
    );
  }

  static Page<T> fadeThrough<T>({
    required LocalKey key,
    required Widget child,
    required bool reduceMotion,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      transitionDuration: AppMotion.of(AppMotion.fadeThrough, reduceMotion),
      reverseTransitionDuration: AppMotion.of(
        AppMotion.fadeThrough,
        reduceMotion,
      ),
      transitionsBuilder: (context, animation, secondary, child) {
        return _FadeThroughTransition(
          animation: animation,
          secondary: secondary,
          reduceMotion: reduceMotion,
          child: child,
        );
      },
      child: AdaptivePage(child: child),
    );
  }

  static Page<T> modalUp<T>({
    required LocalKey key,
    required Widget child,
    required bool reduceMotion,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      fullscreenDialog: true,
      transitionDuration: AppMotion.of(AppMotion.modalIn, reduceMotion),
      reverseTransitionDuration: AppMotion.of(AppMotion.modalOut, reduceMotion),
      transitionsBuilder: (context, animation, secondary, child) {
        return _SlideUpTransition(
          animation: animation,
          reduceMotion: reduceMotion,
          curve: Curves.easeOutCubic,
          child: child,
        );
      },
      child: AdaptivePage(child: child),
    );
  }

  static Page<T> sheet<T>({
    required LocalKey key,
    required Widget child,
    required bool reduceMotion,
    required String barrierLabel,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      opaque: false,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.of(AppMotion.modalIn, reduceMotion),
      reverseTransitionDuration: AppMotion.of(AppMotion.modalOut, reduceMotion),
      transitionsBuilder: (context, animation, secondary, child) {
        return _SlideUpTransition(
          animation: animation,
          reduceMotion: reduceMotion,
          curve: const SheetSpringCurve(),
          child: child,
        );
      },
      child: child,
    );
  }

  static Page<T> dialog<T>({
    required LocalKey key,
    required Widget child,
    required bool reduceMotion,
    required String barrierLabel,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      opaque: false,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.of(AppMotion.dialog, reduceMotion),
      reverseTransitionDuration: AppMotion.of(AppMotion.dialog, reduceMotion),
      transitionsBuilder: (context, animation, secondary, child) {
        return _DialogTransition(
          animation: animation,
          reduceMotion: reduceMotion,
          child: child,
        );
      },
      child: child,
    );
  }

  static Page<T> tabCrossFade<T>({
    required LocalKey key,
    required Widget child,
    required bool reduceMotion,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      transitionDuration: AppMotion.of(AppMotion.tab, reduceMotion),
      reverseTransitionDuration: AppMotion.of(AppMotion.tab, reduceMotion),
      transitionsBuilder: (context, animation, secondary, child) {
        return _FadeTransitionOnce(animation: animation, child: child);
      },
      child: AdaptivePage(child: child),
    );
  }
}

class _FadeTransitionOnce extends StatefulWidget {
  const _FadeTransitionOnce({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_FadeTransitionOnce> createState() => _FadeTransitionOnceState();
}

class _FadeTransitionOnceState extends State<_FadeTransitionOnce> {
  late final CurvedAnimation _opacity;

  @override
  void initState() {
    super.initState();
    _opacity = CurvedAnimation(parent: widget.animation, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _FadeThroughTransition extends StatefulWidget {
  const _FadeThroughTransition({
    required this.animation,
    required this.secondary,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondary;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_FadeThroughTransition> createState() => _FadeThroughTransitionState();
}

class _FadeThroughTransitionState extends State<_FadeThroughTransition> {
  late final CurvedAnimation _in;
  late final Animation<double> _scale;
  late final Animation<double> _out;

  @override
  void initState() {
    super.initState();
    _in = CurvedAnimation(parent: widget.animation, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.98, end: 1).animate(_in);
    _out = Tween<double>(begin: 1, end: 0).animate(widget.secondary);
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return FadeTransition(opacity: _in, child: widget.child);
    }
    return FadeTransition(
      opacity: _out,
      child: FadeTransition(
        opacity: _in,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class _SlideUpTransition extends StatefulWidget {
  const _SlideUpTransition({
    required this.animation,
    required this.reduceMotion,
    required this.curve,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Curve curve;
  final Widget child;

  @override
  State<_SlideUpTransition> createState() => _SlideUpTransitionState();
}

class _SlideUpTransitionState extends State<_SlideUpTransition> {
  late final CurvedAnimation _curved;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _curved = CurvedAnimation(parent: widget.animation, curve: widget.curve);
    _position = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_curved);
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return FadeTransition(opacity: _curved, child: widget.child);
    }
    return SlideTransition(position: _position, child: widget.child);
  }
}

class _DialogTransition extends StatefulWidget {
  const _DialogTransition({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_DialogTransition> createState() => _DialogTransitionState();
}

class _DialogTransitionState extends State<_DialogTransition> {
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
    return FadeTransition(
      opacity: _curved,
      child: ScaleTransition(
        scale: widget.reduceMotion ? const AlwaysStoppedAnimation(1) : _scale,
        child: widget.child,
      ),
    );
  }
}

class _PushPage<T> extends Page<T> {
  const _PushPage({required this.child, required this.reduceMotion, super.key});

  final Widget child;
  final bool reduceMotion;

  @override
  Route<T> createRoute(BuildContext context) {
    if (reduceMotion) {
      return PageRouteBuilder<T>(
        settings: this,
        transitionDuration: AppMotion.reduce,
        reverseTransitionDuration: AppMotion.reduce,
        pageBuilder: (context, animation, secondary) => child,
        transitionsBuilder: (context, animation, secondary, child) {
          return _FadeTransitionOnce(animation: animation, child: child);
        },
      );
    }
    return CupertinoPageRoute<T>(settings: this, builder: (context) => child);
  }
}

/// Cross-fade between shell branches. Each branch stays mounted.
class TabCrossFadeStack extends StatefulWidget {
  const TabCrossFadeStack({
    super.key,
    required this.index,
    required this.reduceMotion,
    required this.children,
  });

  final int index;
  final bool reduceMotion;
  final List<Widget> children;

  @override
  State<TabCrossFadeStack> createState() => _TabCrossFadeStackState();
}

class _TabCrossFadeStackState extends State<TabCrossFadeStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  late final ReverseAnimation _reverse;
  late int _current;
  int? _from;

  @override
  void initState() {
    super.initState();
    _current = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.of(AppMotion.tab, widget.reduceMotion),
      value: 1,
    );
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _reverse = ReverseAnimation(_curved);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _from != null && mounted) {
        setState(() => _from = null);
      }
    });
  }

  @override
  void didUpdateWidget(TabCrossFadeStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = AppMotion.of(AppMotion.tab, widget.reduceMotion);
    if (widget.index != _current) {
      _from = _current;
      _current = widget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [for (var i = 0; i < widget.children.length; i++) _branch(i)],
    );
  }

  Widget _branch(int i) {
    final active = i == _current;
    final leaving = i == _from;
    return Offstage(
      offstage: !active && !leaving,
      child: IgnorePointer(
        ignoring: !active,
        child: FadeTransition(
          opacity: active
              ? _curved
              : leaving
              ? _reverse
              : const AlwaysStoppedAnimation<double>(0),
          child: widget.children[i],
        ),
      ),
    );
  }
}
