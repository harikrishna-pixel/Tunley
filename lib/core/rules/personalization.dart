import 'size_estimator.dart';

enum UserGoal { ringtones, mp3FromVideos, convertFiles }

enum UsageFrequency { everyDay, fewTimesAWeek, onceInAWhile }

enum ConvertMode { ringtone, audioFile }

enum PickerSource { videos, audioFiles }

class Personalization {
  const Personalization({required this.goal, required this.frequency});

  final UserGoal goal;
  final UsageFrequency frequency;

  ConvertMode get convertMode => switch (goal) {
    UserGoal.ringtones => ConvertMode.ringtone,
    UserGoal.mp3FromVideos || UserGoal.convertFiles => ConvertMode.audioFile,
  };

  PickerSource? get picker => switch (goal) {
    UserGoal.ringtones => null,
    UserGoal.mp3FromVideos => PickerSource.videos,
    UserGoal.convertFiles => PickerSource.audioFiles,
  };

  /// Null means keep the last format the user chose.
  AudioPreset? get defaultPreset => switch (goal) {
    UserGoal.mp3FromVideos => AudioPreset.high,
    UserGoal.ringtones || UserGoal.convertFiles => null,
  };

  bool get emphasiseYearly => frequency == UsageFrequency.everyDay;

  bool get lifetimeListedSecond => frequency == UsageFrequency.onceInAWhile;

  bool get p4EveryThreeSessions => frequency == UsageFrequency.onceInAWhile;
}
