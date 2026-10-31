import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tunely/app/router.dart';

/// `04` › Screen transitions: every route builds its page through
/// `AppTransitions` (push = CupertinoPageRoute with swipe-back, modal-up,
/// fade-through, tab cross-fade); none falls back to a default builder.
void main() {
  test('every route uses a pageBuilder (AppTransitions)', () {
    final router = createRouter();
    addTearDown(router.dispose);
    final missing = <String>[];
    void walk(List<RouteBase> routes) {
      for (final route in routes) {
        if (route is GoRoute &&
            (route.pageBuilder == null || route.builder != null)) {
          missing.add(route.path);
        }
        walk(route.routes);
        if (route is StatefulShellRoute) {
          for (final branch in route.branches) {
            walk(branch.routes);
          }
        }
      }
    }

    walk(router.configuration.routes);
    expect(missing, isEmpty);
  });
}
