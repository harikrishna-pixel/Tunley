/// Milestones (30, `05` §5): first ringtone, 10 files, 50 files. Once each.
sealed class Milestone {
  const Milestone();

  /// Stable id persisted once shown.
  String get key;
}

class FirstRingtoneMilestone extends Milestone {
  const FirstRingtoneMilestone();

  @override
  String get key => 'ringtone_1';
}

class FilesMilestone extends Milestone {
  const FilesMilestone(this.files);

  final int files;

  @override
  String get key => 'files_$files';
}

abstract final class MilestoneRules {
  /// [thresholds] comes from `app_config.json` (`[1, 10, 50]`): the first
  /// entry is the first ringtone, the rest are lifetime files.
  static Milestone? due({
    required List<int> thresholds,
    required int ringtonesSaved,
    required int lifetimeFiles,
    required bool justMadeRingtone,
    required Set<String> shown,
  }) {
    if (thresholds.isEmpty) return null;
    const first = FirstRingtoneMilestone();
    if (justMadeRingtone &&
        ringtonesSaved >= thresholds.first &&
        !shown.contains(first.key)) {
      return first;
    }
    // Only the highest milestone reached; lower ones that were missed (for
    // example during a batch) are not shown late.
    for (final files in thresholds.skip(1).toList().reversed) {
      if (lifetimeFiles < files) continue;
      final milestone = FilesMilestone(files);
      return shown.contains(milestone.key) ? null : milestone;
    }
    return null;
  }
}
