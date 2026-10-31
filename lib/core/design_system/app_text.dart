import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Plus Jakarta Sans styles from `design-tokens.json`.
@immutable
class AppText extends ThemeExtension<AppText> {
  const AppText({
    required this.largeTitle,
    required this.title,
    required this.heroTitle,
    required this.timecode,
    required this.dialogTitle,
    required this.navTitle,
    required this.sectionTitle,
    required this.button,
    required this.body,
    required this.subhead,
    required this.caption,
    required this.footnote,
    required this.micro,
  });

  static const family = 'Plus Jakarta Sans';

  final TextStyle largeTitle;
  final TextStyle title;
  final TextStyle heroTitle;
  final TextStyle timecode;
  final TextStyle dialogTitle;
  final TextStyle navTitle;
  final TextStyle sectionTitle;
  final TextStyle button;
  final TextStyle body;
  final TextStyle subhead;
  final TextStyle caption;
  final TextStyle footnote;
  final TextStyle micro;

  factory AppText.from(AppColors colors) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      required Color color,
      double tracking = 0,
      double? height,
      bool tabular = false,
    }) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: tracking == 0 ? null : size * tracking,
        height: height,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );
    }

    return AppText(
      largeTitle: style(
        size: 26,
        weight: FontWeight.w800,
        color: colors.text,
        tracking: -0.03,
      ),
      title: style(
        size: 26,
        weight: FontWeight.w800,
        color: colors.text,
        tracking: -0.02,
      ),
      heroTitle: style(
        size: 22,
        weight: FontWeight.w800,
        color: colors.heroText,
        tracking: -0.02,
      ),
      timecode: style(
        size: 32,
        weight: FontWeight.w800,
        color: colors.text,
        tabular: true,
      ),
      dialogTitle: style(size: 20, weight: FontWeight.w800, color: colors.text),
      navTitle: style(size: 17, weight: FontWeight.w800, color: colors.text),
      sectionTitle: style(
        size: 17,
        weight: FontWeight.w800,
        color: colors.text,
      ),
      button: style(
        size: 16,
        weight: FontWeight.w800,
        color: colors.accentText,
      ),
      body: style(
        size: 15,
        weight: FontWeight.w600,
        color: colors.text,
        height: 1.45,
      ),
      subhead: style(size: 14, weight: FontWeight.w700, color: colors.text),
      caption: style(size: 13, weight: FontWeight.w600, color: colors.text3),
      footnote: style(size: 12, weight: FontWeight.w600, color: colors.text3),
      micro: style(size: 11, weight: FontWeight.w700, color: colors.text3),
    );
  }

  @override
  AppText copyWith({
    TextStyle? largeTitle,
    TextStyle? title,
    TextStyle? heroTitle,
    TextStyle? timecode,
    TextStyle? dialogTitle,
    TextStyle? navTitle,
    TextStyle? sectionTitle,
    TextStyle? button,
    TextStyle? body,
    TextStyle? subhead,
    TextStyle? caption,
    TextStyle? footnote,
    TextStyle? micro,
  }) {
    return AppText(
      largeTitle: largeTitle ?? this.largeTitle,
      title: title ?? this.title,
      heroTitle: heroTitle ?? this.heroTitle,
      timecode: timecode ?? this.timecode,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      navTitle: navTitle ?? this.navTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      button: button ?? this.button,
      body: body ?? this.body,
      subhead: subhead ?? this.subhead,
      caption: caption ?? this.caption,
      footnote: footnote ?? this.footnote,
      micro: micro ?? this.micro,
    );
  }

  @override
  AppText lerp(AppText? other, double t) {
    if (other == null) {
      return this;
    }
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppText(
      largeTitle: mix(largeTitle, other.largeTitle),
      title: mix(title, other.title),
      heroTitle: mix(heroTitle, other.heroTitle),
      timecode: mix(timecode, other.timecode),
      dialogTitle: mix(dialogTitle, other.dialogTitle),
      navTitle: mix(navTitle, other.navTitle),
      sectionTitle: mix(sectionTitle, other.sectionTitle),
      button: mix(button, other.button),
      body: mix(body, other.body),
      subhead: mix(subhead, other.subhead),
      caption: mix(caption, other.caption),
      footnote: mix(footnote, other.footnote),
      micro: mix(micro, other.micro),
    );
  }
}
