import 'package:flutter/material.dart';

/// Direction A colour tokens. Widgets read these through [BuildContext.colors].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.divider,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.accentOnSoft,
    required this.link,
    required this.success,
    required this.successSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
    required this.heroColors,
    required this.heroText,
    required this.heroButtonText,
    required this.tab,
    required this.toast,
    required this.toastAction,
    required this.shadow,
    required this.scrim,
    required this.gold,
    required this.proBadgeBg,
    required this.proBadgeText,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color divider;
  final Color text;
  final Color text2;
  final Color text3;
  final Color accent;
  final Color accentText;
  final Color accentSoft;
  final Color accentOnSoft;
  final Color link;
  final Color success;
  final Color successSoft;
  final Color warn;
  final Color warnSoft;
  final Color danger;
  final Color dangerSoft;
  final List<Color> heroColors;
  final Color heroText;

  /// Inner button label on the hero card. Same violet in both themes (`04`).
  final Color heroButtonText;
  final Color tab;
  final Color toast;

  /// Action label on the always-dark toast surface.
  final Color toastAction;
  final List<BoxShadow> shadow;
  final Color scrim;
  final Color gold;
  final Color proBadgeBg;
  final Color proBadgeText;

  static const List<double> heroStops = [0, 0.55, 1];

  static const light = AppColors(
    brightness: Brightness.light,
    bg: Color(0xFFF5F4FA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEECF6),
    border: Color(0xFFE5E2F0),
    divider: Color(0xFFEFEDF5),
    text: Color(0xFF15132B),
    text2: Color(0xFF5C5875),
    text3: Color(0xFF6B6784),
    accent: Color(0xFF5B3FE6),
    accentText: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFEEEAFF),
    accentOnSoft: Color(0xFF3F25C9),
    link: Color(0xFF5B3FE6),
    success: Color(0xFF0F7350),
    successSoft: Color(0xFFE4F4EC),
    warn: Color(0xFF9A5A12),
    warnSoft: Color(0xFFFDF0DF),
    danger: Color(0xFFC2331F),
    dangerSoft: Color(0xFFFDECEA),
    heroColors: [Color(0xFF3F25C9), Color(0xFF5B3FE6), Color(0xFF7B4DFF)],
    heroText: Color(0xFFFFFFFF),
    heroButtonText: Color(0xFF3F25C9),
    tab: Color(0xF0FFFFFF),
    toast: Color(0xFF1C1A2E),
    toastAction: Color(0xFFB3A1FF),
    shadow: [
      BoxShadow(color: Color(0x0D15132B), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0F15132B), offset: Offset(0, 8), blurRadius: 24),
    ],
    scrim: Color(0x85100C28),
    gold: Color(0xFFE0A21B),
    proBadgeBg: Color(0xFF15132B),
    proBadgeText: Color(0xFFFFD36B),
  );

  static const dark = AppColors(
    brightness: Brightness.dark,
    bg: Color(0xFF0E0D16),
    surface: Color(0xFF181626),
    surface2: Color(0xFF221F33),
    border: Color(0xFF2C2942),
    divider: Color(0xFF25223A),
    text: Color(0xFFF3F1FF),
    text2: Color(0xFFABA7C6),
    text3: Color(0xFF8C88A8),
    accent: Color(0xFF6F4EF2),
    accentText: Color(0xFFFFFFFF),
    accentSoft: Color(0x2E8466FF),
    accentOnSoft: Color(0xFFC4B5FF),
    link: Color(0xFFB3A1FF),
    success: Color(0xFF3CCB8C),
    successSoft: Color(0x243CCB8C),
    warn: Color(0xFFF2B25C),
    warnSoft: Color(0x24F2B25C),
    danger: Color(0xFFFF7A68),
    dangerSoft: Color(0x24FF7A68),
    heroColors: [Color(0xFF3A22BD), Color(0xFF5537E0), Color(0xFF7A4FFF)],
    heroText: Color(0xFFFFFFFF),
    heroButtonText: Color(0xFF3F25C9),
    tab: Color(0xF0181626),
    toast: Color(0xFF2E2A48),
    toastAction: Color(0xFFB3A1FF),
    shadow: [
      BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    scrim: Color(0xA3000000),
    gold: Color(0xFFE0A21B),
    proBadgeBg: Color(0xFFF3F1FF),
    proBadgeText: Color(0xFF3F25C9),
  );

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: heroColors,
    stops: heroStops,
  );

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? divider,
    Color? text,
    Color? text2,
    Color? text3,
    Color? accent,
    Color? accentText,
    Color? accentSoft,
    Color? accentOnSoft,
    Color? link,
    Color? success,
    Color? successSoft,
    Color? warn,
    Color? warnSoft,
    Color? danger,
    Color? dangerSoft,
    List<Color>? heroColors,
    Color? heroText,
    Color? heroButtonText,
    Color? tab,
    Color? toast,
    Color? toastAction,
    List<BoxShadow>? shadow,
    Color? scrim,
    Color? gold,
    Color? proBadgeBg,
    Color? proBadgeText,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentSoft: accentSoft ?? this.accentSoft,
      accentOnSoft: accentOnSoft ?? this.accentOnSoft,
      link: link ?? this.link,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      heroColors: heroColors ?? this.heroColors,
      heroText: heroText ?? this.heroText,
      heroButtonText: heroButtonText ?? this.heroButtonText,
      tab: tab ?? this.tab,
      toast: toast ?? this.toast,
      toastAction: toastAction ?? this.toastAction,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      gold: gold ?? this.gold,
      proBadgeBg: proBadgeBg ?? this.proBadgeBg,
      proBadgeText: proBadgeText ?? this.proBadgeText,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentOnSoft: Color.lerp(accentOnSoft, other.accentOnSoft, t)!,
      link: Color.lerp(link, other.link, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      heroColors: [
        for (var i = 0; i < heroColors.length; i++)
          Color.lerp(heroColors[i], other.heroColors[i], t)!,
      ],
      heroText: Color.lerp(heroText, other.heroText, t)!,
      heroButtonText: Color.lerp(heroButtonText, other.heroButtonText, t)!,
      tab: Color.lerp(tab, other.tab, t)!,
      toast: Color.lerp(toast, other.toast, t)!,
      toastAction: Color.lerp(toastAction, other.toastAction, t)!,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      proBadgeBg: Color.lerp(proBadgeBg, other.proBadgeBg, t)!,
      proBadgeText: Color.lerp(proBadgeText, other.proBadgeText, t)!,
    );
  }
}
