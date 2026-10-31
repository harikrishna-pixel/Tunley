import 'package:flutter/widgets.dart';

import 'phosphor_duotone_secondary.dart';

// Tunely patch: Flutter 3.47 made IconData a final class whose arguments must
// be constants, so these are extension types over const IconData literals
// instead of subclasses.

extension type const PhosphorIconData(IconData icon) implements IconData {}

extension type const PhosphorFlatIconData(IconData icon)
    implements PhosphorIconData {}

extension type const PhosphorDuotoneIconData(IconData icon)
    implements PhosphorIconData {
  IconData? get secondary => secondaryOf(icon);

  /// The secondary layer of a duotone icon, or null for any other icon.
  static IconData? secondaryOf(IconData icon) {
    if (icon.fontFamily != 'PhosphorDuotone' ||
        icon.fontPackage != 'phosphor_flutter') {
      return null;
    }
    return phosphorDuotoneSecondary[icon.codePoint];
  }
}
