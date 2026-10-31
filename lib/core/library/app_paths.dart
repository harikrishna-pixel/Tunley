import 'dart:io';

/// App container paths. Stored paths are relative to `Documents/` because the
/// iOS container path changes between installs and updates.
class AppPaths {
  const AppPaths(this.container);

  /// `NSTemporaryDirectory()` is `<container>/tmp/` on iOS.
  factory AppPaths.fromSystem() => AppPaths(Directory.systemTemp.parent.path);

  final String container;

  String get documents => '$container/Documents';
  String get support => '$container/Library/Application Support';
  String get databaseFile => '$support/tunely.sqlite';
  String get thumbnails => '$support/thumbs';

  /// For paths stored relative to the container (thumbnails).
  String inContainer(String relative) => '$container/$relative';

  String containerRelative(String absolute) {
    final prefix = '$container/';
    return absolute.startsWith(prefix)
        ? absolute.substring(prefix.length)
        : absolute;
  }

  String absolute(String relative) =>
      relative.startsWith('/') ? relative : '$documents/$relative';

  String relative(String absolute) {
    final prefix = '$documents/';
    if (absolute.startsWith(prefix)) {
      return absolute.substring(prefix.length);
    }
    final marker = absolute.indexOf('/Documents/');
    return marker >= 0
        ? absolute.substring(marker + '/Documents/'.length)
        : absolute;
  }
}
