import 'package:flutter/widgets.dart';

/// 4-pt spacing scale from `design-tokens.json`.
abstract final class AppSpace {
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double screen = 20;
}

/// Corner radii from `design-tokens.json`, plus component radii from `04`.
abstract final class AppRadius {
  static const double badge = 6;
  static const double chip = 12;
  static const double button = 16;
  static const double row = 16;
  static const double card = 18;
  static const double hero = 24;
  static const double dialog = 24;
  static const double sheet = 28;

  /// Status box radius from `04` › Components (not in the token radius map).
  static const double status = 14;

  /// Pro chip pill radius from `04` › Components.
  static const double proChip = 17;
}

abstract final class AppBlur {
  static const double overlay = 10;
}

/// Durations from `04` › Screen transitions.
abstract final class AppMotion {
  static const Duration push = Duration(milliseconds: 350);
  static const Duration modalIn = Duration(milliseconds: 350);
  static const Duration modalOut = Duration(milliseconds: 250);
  static const Duration tab = Duration(milliseconds: 200);
  static const Duration fadeThrough = Duration(milliseconds: 300);
  static const Duration dialog = Duration(milliseconds: 200);
  static const Duration scrim = Duration(milliseconds: 200);
  static const Duration toastIn = Duration(milliseconds: 250);
  static const Duration toastOut = Duration(milliseconds: 200);
  static const Duration reduce = Duration(milliseconds: 150);

  static Duration of(Duration full, bool reduceMotion) =>
      reduceMotion ? reduce : full;
}

/// Soft spring used by sheets. Damping ratio is about 0.86.
class SheetSpringCurve extends Curve {
  const SheetSpringCurve();

  @override
  double transformInternal(double t) {
    return const Cubic(0.2, 1.05, 0.32, 1).transformInternal(t);
  }
}
