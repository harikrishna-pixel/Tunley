import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/core/design_system/app_colors.dart';

void main() {
  test('light and dark tokens match design-tokens.json', () {
    expect(AppColors.light.bg, const Color(0xFFF5F4FA));
    expect(AppColors.light.surface, const Color(0xFFFFFFFF));
    expect(AppColors.light.text, const Color(0xFF15132B));
    expect(AppColors.light.accent, const Color(0xFF5B3FE6));
    expect(AppColors.light.link, const Color(0xFF5B3FE6));
    expect(AppColors.light.success, const Color(0xFF0F7350));
    expect(AppColors.light.proBadgeBg, const Color(0xFF15132B));
    expect(AppColors.light.proBadgeText, const Color(0xFFFFD36B));
    expect(AppColors.light.heroColors, const [
      Color(0xFF3F25C9),
      Color(0xFF5B3FE6),
      Color(0xFF7B4DFF),
    ]);

    expect(AppColors.dark.bg, const Color(0xFF0E0D16));
    expect(AppColors.dark.surface, const Color(0xFF181626));
    expect(AppColors.dark.text, const Color(0xFFF3F1FF));
    expect(AppColors.dark.accent, const Color(0xFF6F4EF2));
    expect(AppColors.dark.link, const Color(0xFFB3A1FF));
    expect(AppColors.dark.proBadgeBg, const Color(0xFFF3F1FF));
    expect(AppColors.dark.proBadgeText, const Color(0xFF3F25C9));
    expect(AppColors.dark.heroButtonText, const Color(0xFF3F25C9));
  });
}
