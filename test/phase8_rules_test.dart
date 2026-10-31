import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/core/rules/merge_rules.dart';
import 'package:tunely/core/rules/milestone_rules.dart';
import 'package:tunely/core/rules/update_rules.dart';

void main() {
  group('MergeRules', () {
    test('2 to 10 files', () {
      expect(MergeRules.canMerge(1, maxFiles: 10), isFalse);
      expect(MergeRules.canMerge(2, maxFiles: 10), isTrue);
      expect(MergeRules.canMerge(10, maxFiles: 10), isTrue);
      expect(MergeRules.canMerge(11, maxFiles: 10), isFalse);
      expect(MergeRules.room(8, maxFiles: 10), 2);
      expect(MergeRules.room(12, maxFiles: 10), 0);
    });

    test('total = sum minus crossfades', () {
      expect(MergeRules.totalSeconds([72, 38, 42, 70], 0), 222);
      expect(MergeRules.totalSeconds([72, 38, 42, 70], 1), 219);
      expect(MergeRules.totalSeconds([72, 38, 42, 70], 3), 213);
      expect(MergeRules.totalSeconds([], 2), 0);
    });

    test('a crossfade never eats more than half the shorter file', () {
      expect(MergeRules.totalSeconds([2, 60], 3), 61);
    });
  });

  group('MilestoneRules', () {
    Milestone? due({
      int ringtones = 0,
      int files = 0,
      bool ringtone = false,
      Set<String> shown = const {},
    }) => MilestoneRules.due(
      thresholds: const [1, 10, 50],
      ringtonesSaved: ringtones,
      lifetimeFiles: files,
      justMadeRingtone: ringtone,
      shown: shown,
    );

    test('first ringtone once', () {
      expect(
        due(ringtones: 1, files: 1, ringtone: true),
        isA<FirstRingtoneMilestone>(),
      );
      expect(
        due(ringtones: 2, files: 2, ringtone: true, shown: {'ringtone_1'}),
        isNull,
      );
      expect(due(ringtones: 0, files: 1), isNull);
    });

    test('10 and 50 files, once each, highest reached only', () {
      expect(due(files: 9), isNull);
      expect((due(files: 10) as FilesMilestone).files, 10);
      expect(due(files: 11, shown: {'files_10'}), isNull);
      expect((due(files: 50, shown: {'files_10'}) as FilesMilestone).files, 50);
      expect((due(files: 55) as FilesMilestone).files, 50);
      expect(due(files: 60, shown: {'files_50'}), isNull);
    });
  });

  group('UpdateRules', () {
    test('compares versions numerically', () {
      expect(UpdateRules.compare('1.10.0', '1.9.2'), greaterThan(0));
      expect(UpdateRules.compare('1.0', '1.0.0'), 0);
      expect(UpdateRules.compare('1.0.0+5', '1.0.1'), lessThan(0));
    });

    test('only when minRecommended is newer, once per version', () {
      expect(
        UpdateRules.shouldShow(
          current: '1.0.0',
          latest: '1.0.0',
          minRecommended: '1.0.0',
          shownForVersion: null,
        ),
        isFalse,
      );
      expect(
        UpdateRules.shouldShow(
          current: '1.0.0',
          latest: '1.2.0',
          minRecommended: '1.0.0',
          shownForVersion: null,
        ),
        isFalse,
      );
      expect(
        UpdateRules.shouldShow(
          current: '1.0.0',
          latest: '1.2.0',
          minRecommended: '1.1.0',
          shownForVersion: null,
        ),
        isTrue,
      );
      expect(
        UpdateRules.shouldShow(
          current: '1.0.0',
          latest: '1.2.0',
          minRecommended: '1.1.0',
          shownForVersion: '1.2.0',
        ),
        isFalse,
      );
    });
  });
}
