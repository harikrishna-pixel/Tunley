# phosphor_flutter (vendored, patched)

Upstream phosphor_flutter 2.1.0 (MIT, see LICENSE) does not compile on Flutter 3.47+, where
`IconData` became a final class. This copy changes `PhosphorIconData`, `PhosphorFlatIconData` and
`PhosphorDuotoneIconData` into extension types over `IconData` (same const API) and looks up duotone
secondary layers from `phosphor_duotone_secondary.dart`. Nothing else is changed.

Remove this folder and the `dependency_overrides` entry in the root `pubspec.yaml` once upstream ships a
compatible release.
