import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/app/config.dart';

void main() {
  test('app_config.json matches the handoff defaults', () async {
    final raw = await File('assets/config/app_config.json').readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final config = AppConfig.fromJson(json);

    expect(config.freeConversionsPerDay, 3);
    expect(config.ringtoneMaxSeconds, 30);
    expect(config.textToneDefaultSeconds, 5);
    expect(config.fadeDefaultSeconds, 2);
    expect(config.fadeMaxSeconds, 5);
    expect(config.batchMaxFiles, 50);
    expect(config.mergeMaxFiles, 10);
    expect(config.volumeBoostMaxDb, 6);
    expect(config.exitOfferMinutes, 10);
    expect(config.maxUnrequestedPaywallsPerSession, 1);
    expect(config.rating.afterConversions, 5);
    expect(config.rating.delayMs, 1500);
    expect(config.milestones, [1, 10, 50]);
    expect(config.ads.enabled, isTrue);
    expect(config.ads.provider, 'admob');
    expect(config.ads.maxPerDay, 6);
    expect(config.moreApps.map((app) => app.id), [
      'shrink',
      'biblehi',
      'imageresizer',
    ]);
    expect(config.houseCard.everyNthSuccess, 5);
    expect(config.referral.enabled, isTrue);
    expect(config.referral.friendDays, 7);
    expect(config.referral.inviterDays, 7);
    expect(config.referral.yearlyCap, 10);
    expect(config.update.latest, '1.0.0');
  });
}
