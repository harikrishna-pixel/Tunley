import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics/analytics.dart';
import '../../core/analytics/events.dart';

/// `file_shared.target` from the activity iOS reports; null when dismissed.
String? shareTarget(ShareResult result) {
  return switch (result.status) {
    ShareResultStatus.dismissed => null,
    ShareResultStatus.unavailable => 'unknown',
    ShareResultStatus.success =>
      result.raw.contains('AirDrop')
          ? 'airdrop'
          : result.raw.contains('Message')
          ? 'messages'
          : result.raw.isEmpty
          ? 'unknown'
          : 'other',
  };
}

/// Opens the share sheet; sends `file_shared` only when it completed.
Future<void> shareAndTrack(
  WidgetRef ref,
  ShareParams params, {
  required String format,
  required String screen,
}) async {
  final result = await SharePlus.instance.share(params);
  final target = shareTarget(result);
  if (target == null) return;
  ref
      .read(analyticsProvider)
      .fileShared(target: target, format: format, screen: screen);
}
