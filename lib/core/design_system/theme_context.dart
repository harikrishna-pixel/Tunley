import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

extension TunelyTheme on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  AppText get appText => Theme.of(this).extension<AppText>()!;
}
