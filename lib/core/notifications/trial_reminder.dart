import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local notification 24 h before a free trial ends (O4 promise). The copy
/// never promises delivery; P7 also shows in-app when notifications are off.
abstract class TrialReminder {
  /// [onOpened] fires when the trial reminder is tapped, [onBatchOpened] when
  /// the "batch finished" notification is.
  Future<void> init({
    required void Function() onOpened,
    void Function()? onBatchOpened,
  });
  Future<bool> get openedFromReminder;
  Future<bool> notificationsAllowed();

  /// Asks iOS for permission. Returns whether alerts are allowed.
  Future<bool> requestPermission();
  Future<void> schedule(
    DateTime at, {
    required String title,
    required String body,
  });
  Future<void> cancel();

  /// Sent only after a batch really finished in the background (`05` §9).
  Future<void> notifyBatchDone({required String title, required String body});
}

class LocalTrialReminder implements TrialReminder {
  static const _id = 7;
  static const payload = 'p7';
  static const _batchId = 8;
  static const batchPayload = 'batch';
  final _plugin = FlutterLocalNotificationsPlugin();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({
    required void Function() onOpened,
    void Function()? onBatchOpened,
  }) async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == payload) onOpened();
        if (response.payload == batchPayload) onBatchOpened?.call();
      },
    );
  }

  @override
  Future<bool> get openedFromReminder async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return (details?.didNotificationLaunchApp ?? false) &&
        details?.notificationResponse?.payload == payload;
  }

  @override
  Future<bool> notificationsAllowed() async =>
      (await _ios?.checkPermissions())?.isEnabled ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _ios?.requestPermissions(alert: true, sound: true) ?? false;

  @override
  Future<void> schedule(
    DateTime at, {
    required String title,
    required String body,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: _id,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(id: _id);

  @override
  Future<void> notifyBatchDone({
    required String title,
    required String body,
  }) async {
    if (!await notificationsAllowed()) return;
    await _plugin.show(
      id: _batchId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      payload: batchPayload,
    );
  }
}
