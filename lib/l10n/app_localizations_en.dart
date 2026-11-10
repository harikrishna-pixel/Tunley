// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabFiles => 'My files';

  @override
  String get tabSettings => 'Settings';

  @override
  String get homeTitle => 'Tunely';

  @override
  String get proBadge => 'PRO';

  @override
  String get proChip => 'Pro';

  @override
  String freeCounter(int remaining, int total) {
    return '$remaining of $total free today';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get continueAction => 'Continue';

  @override
  String get share => 'Share';

  @override
  String get notNow => 'Not now';

  @override
  String get galleryTitle => 'Component gallery';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get showToast => 'Show toast';

  @override
  String get toastSaved => 'Saved on this iPhone';

  @override
  String get undo => 'Undo';

  @override
  String get showSheet => 'Show sheet';

  @override
  String get showDialog => 'Show dialog';

  @override
  String get sheetTitle => 'Trim and fade';

  @override
  String get sheetBody => 'Drag the handles to keep the best part.';

  @override
  String get dialogTitle => 'Stop converting?';

  @override
  String get dialogBody => 'The original file stays unchanged.';

  @override
  String get stop => 'Stop';

  @override
  String get audioFile => 'Audio file';

  @override
  String get ringtone => 'Ringtone';

  @override
  String get highQuality => 'High';

  @override
  String get highQualityDetail => '256 kbps';

  @override
  String get sizeEstimate => '1.3 MB';

  @override
  String get originalSafe => 'Your original file is safe and unchanged';

  @override
  String get heroTitle => 'Make a ringtone from any video';

  @override
  String get heroButton => 'Choose a video';

  @override
  String get playerTitle => 'Summer concert';

  @override
  String get playerMeta => 'MP3 · 256 kbps · 1.3 MB';

  @override
  String get playerElapsed => '0:12';

  @override
  String get playerDuration => '3:05';

  @override
  String get toolVideo => 'Video to MP3';

  @override
  String get toolConvert => 'Convert';

  @override
  String get toolTrim => 'Trim';

  @override
  String get trialToday => 'Today';

  @override
  String get trialDay2 => 'Day 2';

  @override
  String get trialDay3 => 'Day 3';

  @override
  String get trialStart => 'Start your plan';

  @override
  String get trialReminder => 'We remind you';

  @override
  String get trialCharge => 'Plan continues';

  @override
  String get galleryButtons => 'Buttons';

  @override
  String get gallerySegmented => 'Segmented control';

  @override
  String get galleryFormats => 'Format chips';

  @override
  String get galleryQuality => 'Quality';

  @override
  String get galleryTools => 'Tools';

  @override
  String get galleryBadges => 'Badges';

  @override
  String get galleryStatus => 'Status';

  @override
  String get galleryHero => 'Hero';

  @override
  String get galleryPlayer => 'Player';

  @override
  String get galleryWaveform => 'Waveform';

  @override
  String get galleryTrial => 'Trial timeline';

  @override
  String get galleryOverlays => 'Toast, sheet, dialog';

  @override
  String get formatMp3 => 'MP3';

  @override
  String get formatM4a => 'M4A';

  @override
  String get formatFlac => 'FLAC';

  @override
  String get formatWav => 'WAV';

  @override
  String get formatOgg => 'OGG';

  @override
  String get formatM4r => 'M4R';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get waveformRange => 'Selected range';

  @override
  String get formatAac => 'AAC';

  @override
  String get engineDebugTitle => 'Audio engine';

  @override
  String get enginePickVideo => 'Pick a video';

  @override
  String get enginePickAudio => 'Pick an audio file';

  @override
  String get engineConvertAll => 'Convert to every format';

  @override
  String get engineChooseFolder => 'Choose Tunely folder';

  @override
  String get engineCopyToFolder => 'Save to folder';

  @override
  String engineSavedTo(String folder, String name) {
    return 'Saved to $folder as $name';
  }

  @override
  String engineInfo(
    String seconds,
    int sampleRate,
    int channels,
    String bitrate,
  ) {
    return '$seconds s · $sampleRate Hz · $channels ch · $bitrate';
  }

  @override
  String engineBitrate(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get engineBitrateUnknown => 'bitrate unknown';

  @override
  String get engineNoAudio => 'This video has no sound';

  @override
  String get engineProtected => 'This file is copy-protected';

  @override
  String engineResult(String format, String size, String seconds) {
    return '$format · $size · $seconds s';
  }

  @override
  String engineFailed(String format, String code) {
    return '$format failed: $code';
  }

  @override
  String engineUnavailable(String format) {
    return '$format encoder not bundled';
  }

  @override
  String engineFreeSpace(String size) {
    return 'Free space: $size';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get heroEyebrow => 'Your favourite tool';

  @override
  String get heroTitleRingtone => 'Make a ringtone from any video';

  @override
  String get heroTitleMp3 => 'Turn any video into an MP3';

  @override
  String get heroTitleConvert => 'Convert audio to any format';

  @override
  String get heroCtaRingtone => 'Choose a video or song';

  @override
  String get heroCtaMp3 => 'Choose a video';

  @override
  String get heroCtaConvert => 'Choose an audio file';

  @override
  String get homeTools => 'Tools';

  @override
  String get homeRecent => 'Recent';

  @override
  String get seeAll => 'See all';

  @override
  String get toolVideoToMp3 => 'Video to MP3';

  @override
  String get toolConvertFormat => 'Convert format';

  @override
  String get toolTrimFade => 'Trim & fade';

  @override
  String get toolMerge => 'Merge audio';

  @override
  String get toolBoost => 'Volume boost';

  @override
  String get toolBatch => 'Batch convert';

  @override
  String metaFormatBitrateSize(String format, int kbps, String size) {
    return '$format · $kbps kbps · $size';
  }

  @override
  String metaFormatSize(String format, String size) {
    return '$format · $size';
  }

  @override
  String metaRingtone(String duration) {
    return 'Ringtone · $duration';
  }

  @override
  String get toneRingtone => 'Ringtone';

  @override
  String get toneAlarm => 'Alarm';

  @override
  String get toneTextTone => 'Text tone';

  @override
  String get pickerTitle => 'Choose a file';

  @override
  String get pickerVideos => 'Videos';

  @override
  String get pickerAudio => 'Audio files';

  @override
  String get pickerRecent => 'Recent';

  @override
  String get pickerChooseVideos => 'Choose from Photos';

  @override
  String get pickerBrowseFiles => 'Browse Files';

  @override
  String get pickerBrowseFilesHint =>
      'Pick audio from Files, iCloud Drive or other apps';

  @override
  String get pickerVideosHint =>
      'Pick a video from your library. Tunely only sees the videos you choose.';

  @override
  String get pickerRecentEmpty => 'Your converted files will show up here.';

  @override
  String pickerVideoSelected(String duration) {
    return '1 video selected · $duration';
  }

  @override
  String get pickerAudioSelected => '1 audio file selected';

  @override
  String get pickerNothingSelected => 'Nothing selected yet';

  @override
  String get pickerBatchHint => 'Batch up to 50 files with Pro';

  @override
  String get pickerOpenFiles => 'Open Files';

  @override
  String get pickerLoading => 'Getting your file ready';

  @override
  String sourceVideoMeta(String duration, String size) {
    return 'Video · $duration · $size';
  }

  @override
  String sourceAudioMeta(String format, String duration, String size) {
    return '$format · $duration · $size';
  }

  @override
  String get convertTitleAudio => 'Convert to audio';

  @override
  String get convertTitleRingtone => 'Make a ringtone';

  @override
  String get convertFormat => 'Format';

  @override
  String get convertQuality => 'Quality';

  @override
  String get qualityStandard => 'Standard';

  @override
  String get qualityStandardDetail => '128 kbps · voice, podcasts';

  @override
  String get qualityHigh => 'High';

  @override
  String get qualityHighDetail => '256 kbps · music (recommended)';

  @override
  String get qualityBest => 'Best';

  @override
  String get qualityBestDetail => '320 kbps · same as the original';

  @override
  String get qualityLossless => 'Lossless';

  @override
  String get qualityWavDetail => 'Uncompressed · 16-bit, 44.1 kHz';

  @override
  String get qualityFlacDetail => 'Compressed without losing quality';

  @override
  String get trimFade => 'Trim & fade';

  @override
  String trimSummaryFull(String duration) {
    return 'Full $duration';
  }

  @override
  String trimSummaryRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get fadeNone => 'No fade';

  @override
  String get fadeInOnly => 'Fade in';

  @override
  String get fadeOutOnly => 'Fade out';

  @override
  String get fadeBoth => 'Fade in & out';

  @override
  String trimSummary(String range, String fade) {
    return '$range · $fade';
  }

  @override
  String summaryLossy(String format, int kbps, String duration) {
    return '$format · $kbps kbps · $duration';
  }

  @override
  String summaryLossless(String format, String duration) {
    return '$format · $duration';
  }

  @override
  String summarySize(String estimate, String source) {
    return '$estimate (from $source)';
  }

  @override
  String summaryRingtone(int seconds) {
    return 'M4R ringtone · $seconds s';
  }

  @override
  String get readyForIphone => 'Ready for iPhone';

  @override
  String convertCta(String format) {
    return 'Convert to $format';
  }

  @override
  String get createRingtone => 'Create ringtone';

  @override
  String get selectedPart => 'Selected part';

  @override
  String selectedRange(String start, String end, int seconds) {
    return '$start – $end · $seconds s';
  }

  @override
  String selectedRangeLong(String start, String end, int seconds) {
    return 'Selected $start – $end · $seconds s';
  }

  @override
  String get fadeIn => 'Fade in';

  @override
  String get fadeOut => 'Fade out';

  @override
  String fadeSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get volumeBoost => 'Volume boost';

  @override
  String volumeBoostDetail(int db) {
    return 'Pro · up to +$db dB';
  }

  @override
  String volumeBoostDetailPro(int db) {
    return 'Up to +$db dB';
  }

  @override
  String ringtoneInfo(int seconds) {
    return 'iPhone ringtones can be up to $seconds seconds. After saving we\'ll guide you step by step to set it.';
  }

  @override
  String get minusOneSecond => '−1 s';

  @override
  String get plusOneSecond => '+1 s';

  @override
  String get minusOneSecondLabel => 'Back 1 second';

  @override
  String get plusOneSecondLabel => 'Forward 1 second';

  @override
  String get convertingTitle => 'Converting';

  @override
  String secondsLeft(int seconds) {
    return 'about $seconds s left';
  }

  @override
  String get almostDone => 'almost done';

  @override
  String convertingFile(String source, String format) {
    return '$source → $format';
  }

  @override
  String convertingMeta(int kbps, String size) {
    return '$kbps kbps · $size';
  }

  @override
  String get convertingPrivacy =>
      'Converting on your iPhone · nothing is uploaded';

  @override
  String get runInBackground => 'Run in background';

  @override
  String get backgroundCaption =>
      'On iOS 26 it keeps going. On older iOS it may pause until you come back.';

  @override
  String get stopTitle => 'Stop converting?';

  @override
  String get stopBody =>
      'The original file stays unchanged. Nothing is saved and it doesn\'t use a free conversion.';

  @override
  String get stopConfirm => 'Stop';

  @override
  String get keepConverting => 'Keep converting';

  @override
  String get resultTitle => 'Done';

  @override
  String resultReadyAudio(String format) {
    return 'Your $format is ready';
  }

  @override
  String get resultReadyRingtone => 'Your ringtone is ready';

  @override
  String get resultSubAudio => 'Converted on your iPhone · nothing uploaded';

  @override
  String resultSubRingtone(int seconds, String fade) {
    return '$seconds seconds · $fade';
  }

  @override
  String get fadeBothLower => 'fade in and out';

  @override
  String get fadeInLower => 'fade in';

  @override
  String get fadeOutLower => 'fade out';

  @override
  String get noFadeLower => 'no fade';

  @override
  String resultMetaRingtone(String duration) {
    return 'Ringtone · M4R · $duration';
  }

  @override
  String get statVideo => 'Video';

  @override
  String get statAudio => 'Audio';

  @override
  String get statTook => 'Took';

  @override
  String get makeItRingtone => 'Make it a ringtone';

  @override
  String makeItRingtoneDetail(int seconds) {
    return 'Pick the best $seconds seconds';
  }

  @override
  String get alsoSaveMp3 => 'Also save as MP3';

  @override
  String get alsoSaveMp3Detail => 'Keep a copy to share or play anywhere';

  @override
  String get saveToFiles => 'Save to Files';

  @override
  String get setAsRingtone => 'Set as ringtone';

  @override
  String freeLeftLine(int remaining, int total) {
    return '$remaining of $total free conversions left today';
  }

  @override
  String get goUnlimited => 'Go unlimited';

  @override
  String savedToFolder(String folder) {
    return 'Saved to Files › $folder';
  }

  @override
  String get folderGoneTitle => 'We can\'t find your Tunely folder';

  @override
  String get folderGoneBody =>
      'It may have been moved or deleted. Your file is still in My files.';

  @override
  String get chooseFolderAgain => 'Choose folder again';

  @override
  String jobReady(String format) {
    return 'Your $format is ready';
  }

  @override
  String get open => 'Open';

  @override
  String get jobFailedToast => 'Couldn\'t convert this file';

  @override
  String get details => 'Details';

  @override
  String proGateTitle(String feature) {
    return '$feature is part of Tunely Pro';
  }

  @override
  String get proGateBody =>
      'Pro unlocks every format, alarms and text tones, volume boost, merge, batch and unlimited conversions. No ads.';

  @override
  String get proGateCta => 'See Tunely Pro';

  @override
  String get useMp3Instead => 'Use MP3 instead';

  @override
  String featureFormat(String format) {
    return '$format';
  }

  @override
  String limitTitle(int total) {
    return 'You\'ve used today\'s $total free conversions';
  }

  @override
  String get limitBody =>
      'New free conversions arrive at midnight. Your file is still here when you come back.';

  @override
  String get ok => 'OK';

  @override
  String get errorUnreadableTitle => 'We couldn\'t convert this file';

  @override
  String get errorUnreadableBody =>
      'The file may be damaged or in a format we can\'t read.';

  @override
  String get errorNoAudioTitle => 'This video has no sound';

  @override
  String get errorNoAudioBody =>
      'There\'s no audio track to turn into a file. Try a different video.';

  @override
  String get errorProtectedTitle => 'This file is copy-protected';

  @override
  String get errorProtectedBody =>
      'Purchased or rented videos and songs can\'t be converted.';

  @override
  String get errorIcloudTitle => 'Couldn\'t download from iCloud';

  @override
  String get errorIcloudBody => 'Check your connection and try again.';

  @override
  String get errorNoSpaceTitle => 'Not enough space on your iPhone';

  @override
  String errorNoSpaceBody(int mb) {
    return 'Free up $mb MB and try again.';
  }

  @override
  String get errorNoSpaceBodyGeneric => 'Free up some space and try again.';

  @override
  String get errorSaveTitle => 'Couldn\'t save the file';

  @override
  String get errorSaveBody => 'Something went wrong while writing the file.';

  @override
  String get errorInterruptedTitle => 'The conversion was interrupted';

  @override
  String get errorInterruptedBody =>
      'iOS paused Tunely before it finished. Nothing was counted.';

  @override
  String errorCode(String code) {
    return 'Code $code';
  }

  @override
  String sourceBitrateCaption(int kbps) {
    return 'Source is $kbps kbps. Higher won\'t improve it.';
  }

  @override
  String e1Title(String name) {
    return 'Couldn\'t convert $name';
  }

  @override
  String e1Body(int percent) {
    return 'It stopped at $percent%. This sometimes happens with screen recordings that use a variable frame rate.';
  }

  @override
  String get e1BodyNoProgress =>
      'This sometimes happens with screen recordings that use a variable frame rate.';

  @override
  String get e1CardLabel => 'What you can do';

  @override
  String e1Card(String code) {
    return 'Try again in compatibility mode (AAC). It works for almost every video. Error code $code is attached if you contact us.';
  }

  @override
  String e1CardRetried(String code) {
    return 'Compatibility mode couldn\'t read this file either. Error code $code is attached if you contact us.';
  }

  @override
  String get e1Cta => 'Try compatibility mode';

  @override
  String get contactSupport => 'Contact support';

  @override
  String supportCopied(String email) {
    return 'Copied $email and the error code';
  }

  @override
  String e2Title(int mb) {
    return 'Free up $mb MB to continue';
  }

  @override
  String get e2Body =>
      'Converting needs a little room for a temporary copy. It\'s deleted as soon as the file is ready.';

  @override
  String get e2CardLabel => 'Quick ways to make room';

  @override
  String get e2Tip1 => 'Empty Recently Deleted in Photos';

  @override
  String get e2Tip2 => 'Remove old files in My files';

  @override
  String get e2Tip3 => 'Choose Standard quality (smaller file)';

  @override
  String get e2Cta => 'Check again';

  @override
  String get e2Help => 'How to free up space';

  @override
  String get e2HelpTitle => 'How to free up space';

  @override
  String get e2HelpBody =>
      'Open Settings › General › iPhone Storage to see what uses the most space. Offloading unused apps keeps their data, and emptying Recently Deleted in Photos frees space right away.';

  @override
  String e2StillShort(int mb) {
    return 'Still $mb MB short';
  }

  @override
  String get e3Title => 'This video is still in iCloud';

  @override
  String e3Body(String name) {
    return 'Tunely couldn\'t download $name from iCloud. Check your connection, or open it once in Photos so it downloads.';
  }

  @override
  String get e3BodyGeneric =>
      'Tunely couldn\'t download this file from iCloud. Check your connection, or open it once in Photos so it downloads.';

  @override
  String get e3CardLabel => 'Size to download';

  @override
  String e3Card(String size) {
    return '$size over Wi-Fi or mobile data';
  }

  @override
  String get pickAnotherFile => 'Pick another file';

  @override
  String get e4TitleSong => 'This song is copy-protected';

  @override
  String get e4TitleVideo => 'This video is copy-protected';

  @override
  String get e4Body =>
      'Songs from Apple Music and other streaming services are protected, so no app can convert them. Your own videos, voice memos and DRM-free music files work fine.';

  @override
  String get e4CardLabel => 'File';

  @override
  String e4Card(String name, String ext) {
    return '$name · .$ext';
  }

  @override
  String get whatCanIConvert => 'What can I convert?';

  @override
  String get convertibleTitle => 'What Tunely can convert';

  @override
  String get convertibleBody =>
      'Videos you recorded or saved (MOV, MP4, M4V), voice memos and DRM-free audio (MP3, M4A, WAV, AIFF, CAF, FLAC, AAC). Purchased or streamed songs and rented videos are copy-protected.';

  @override
  String get e4bTitle => 'This video has no sound';

  @override
  String get e4bBody =>
      'There\'s no audio track in this video, so there\'s nothing to convert. Try another video, or check the sound wasn\'t muted when it was recorded.';

  @override
  String e4bCard(String name) {
    return '$name · no audio track';
  }

  @override
  String get getHelp => 'Get help';

  @override
  String get noSoundHelpBody =>
      'Some screen recordings and muted clips are saved without an audio track. Record again with the microphone on, or pick a different video.';

  @override
  String get e5Title => 'Couldn\'t save to Files';

  @override
  String get e5BodyFull =>
      'Saving was interrupted because the destination is full.';

  @override
  String get e5Body => 'Something went wrong while saving to Files.';

  @override
  String get e5bTitle => 'Can\'t find your Tunely folder';

  @override
  String get e5bBody =>
      'The folder you chose in Files was moved, renamed or deleted, so Tunely can\'t save there.';

  @override
  String e5Safe(String format) {
    return 'Your $format is safe in Tunely';
  }

  @override
  String e5SafeDetail(int days) {
    return 'Kept for $days days · no need to convert again';
  }

  @override
  String get saveOnIphoneInstead => 'Save on this iPhone instead';

  @override
  String get saveOnIphone => 'Save on this iPhone';

  @override
  String get shareInstead => 'Share instead';

  @override
  String get savedOnIphone =>
      'Saved on this iPhone · Files › On My iPhone › Tunely';

  @override
  String stopBodyProgress(int percent) {
    return 'You\'re $percent% done. This won\'t use one of your free conversions.';
  }

  @override
  String deleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteBody =>
      'It\'s removed from My files on this iPhone. Copies you saved to your Tunely folder in Files are kept, and the original video in Photos is not touched.';

  @override
  String get deleteConfirm => 'Delete from Tunely';

  @override
  String get keep => 'Keep';

  @override
  String get filesEmptyTitle => 'No sounds yet';

  @override
  String get filesEmptyBody =>
      'Your MP3s, ringtones and converted files show up here, and a copy is saved to your Tunely folder in Files.';

  @override
  String get makeFirstSound => 'Make your first sound';

  @override
  String moreFromMarberx(String pitch) {
    return 'More from Marberx · $pitch';
  }

  @override
  String get moreFromMarberxShort => 'More from Marberx';

  @override
  String get get => 'Get';

  @override
  String moreActions(String name) {
    return 'More actions for $name';
  }

  @override
  String get delete => 'Delete';

  @override
  String get toastRingtoneAdded => 'Ringtone added — find it in Sounds';

  @override
  String get toastCopied => 'Copied to clipboard';

  @override
  String toastFreeLeft(int remaining, int total) {
    return '$remaining of $total free conversions left today';
  }

  @override
  String get goPro => 'Go Pro';

  @override
  String get toastWelcomePro => 'Welcome to Tunely Pro!';

  @override
  String get toastIcloud => 'File is still downloading from iCloud…';

  @override
  String get galleryToasts => 'Toast catalogue';

  @override
  String get chooseAnotherFile => 'Choose another file';

  @override
  String get tryAgain => 'Try again';

  @override
  String get skip => 'Skip';

  @override
  String get o1Title => 'Any video,\nyour ringtone';

  @override
  String get o1Body =>
      'Pull the sound out of any video, keep the best part and set it in seconds. MP3 and other formats too.';

  @override
  String get o1DemoTitle => 'Dance night';

  @override
  String get o1DemoMeta => 'Ringtone · 0:30';

  @override
  String get o2Title => 'What do you want to make?';

  @override
  String get o2Body => 'We\'ll put your favourite tool first.';

  @override
  String get goalRingtones => 'Ringtones';

  @override
  String get goalRingtonesDetail => 'Ringtones, alarms and text tones';

  @override
  String get goalMp3 => 'MP3 from videos';

  @override
  String get goalMp3Detail => 'Keep just the sound of a video';

  @override
  String get goalConvert => 'Convert audio files';

  @override
  String get goalConvertDetail => 'MP3, M4A, WAV and more';

  @override
  String get o2Footer => 'You can change this anytime in Settings.';

  @override
  String get o3Title => 'How often will you use Tunely?';

  @override
  String get o3Body => 'So we only suggest what\'s worth it for you.';

  @override
  String get freqDaily => 'Every day';

  @override
  String get freqDailyDetail => 'Music, clips and ringtones all the time';

  @override
  String get freqWeekly => 'A few times a week';

  @override
  String get freqWeeklyDetail => 'Whenever something catches my ear';

  @override
  String get freqRarely => 'Just once in a while';

  @override
  String get freqRarelyDetail => 'A ringtone or a file now and then';

  @override
  String get o4Title => 'Honest and simple.\nNo surprises.';

  @override
  String o4FreeTitle(int count) {
    return '$count free conversions every day';
  }

  @override
  String get o4FreeBody =>
      'Full quality, no watermark. Your free uses come back every morning.';

  @override
  String get o4AdsTitle => 'Short ads, never mid-task';

  @override
  String get o4AdsBody =>
      'Ads only appear between tasks, after your file is saved. Pro removes them.';

  @override
  String get o4TrialTitle => 'A reminder before any trial ends';

  @override
  String get o4TrialBody =>
      'Allow notifications and we\'ll remind you a day before. Cancel in two taps.';

  @override
  String get o4DeviceTitle => 'Made on your iPhone';

  @override
  String get o4DeviceBody =>
      'Your files are converted on the device and never uploaded.';

  @override
  String get soundsGood => 'Sounds good';

  @override
  String get o5Title => 'Your library stays private';

  @override
  String get o5Body =>
      'Tunely only sees the videos and songs you choose. No full photo-library access needed, and nothing is uploaded.';

  @override
  String get o5Pill => 'Only the file you pick';

  @override
  String get getStarted => 'Get started';

  @override
  String get convertedOnIphone => 'Converted on your iPhone';

  @override
  String onboardingStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get proCardTitle => 'Tunely Pro';

  @override
  String get proCardBody => 'Unlimited, no ads, all formats';

  @override
  String get settingsPreferences => 'Your preferences';

  @override
  String get settingsWhatIMake => 'What I make';

  @override
  String get settingsDefaultFormat => 'Default format';

  @override
  String get settingsSaveTo => 'Save to';

  @override
  String get settingsSaveToNone => 'Choose a folder';

  @override
  String settingsSaveToFolder(String folder) {
    return 'Files › $folder';
  }

  @override
  String get settingsHelpMore => 'Help & more';

  @override
  String get settingsHowRingtone => 'How to set a ringtone';

  @override
  String get settingsHelp => 'Help & FAQ';

  @override
  String get settingsRate => 'Rate Tunely';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsManage => 'Manage subscription';

  @override
  String get settingsTerms => 'Terms';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLicences => 'Licences';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsDebug => 'Debug';

  @override
  String get debugUnlockPro => 'Unlock Pro (testing)';

  @override
  String get debugLockPro => 'Lock Pro (testing)';

  @override
  String get editExitTitle => 'Confirm Exit?';

  @override
  String get editExitBody =>
      'Current edits will not be saved. Are you sure you want to exit?';

  @override
  String get editExitConfirm => 'Confirm Exit';

  @override
  String get editExitContinue => 'Continue Editing';

  @override
  String formatKbps(String format, int kbps) {
    return '$format · $kbps kbps';
  }

  @override
  String get defaultFormatTitle => 'Default format';

  @override
  String get defaultFormatBody =>
      'New conversions start with this format and quality. You can still change them each time.';

  @override
  String get save => 'Save';

  @override
  String get couldNotOpen => 'Couldn\'t open that link';

  @override
  String get prefsTitle => 'Your preferences';

  @override
  String get prefsWhat => 'What do you make most?';

  @override
  String get prefsGoalRingtones => 'Ringtones, alarms and text tones';

  @override
  String get prefsGoalMp3 => 'MP3 from videos';

  @override
  String get prefsGoalConvert => 'Converting audio files';

  @override
  String get prefsHowOften => 'How often?';

  @override
  String get prefsDaily => 'Daily';

  @override
  String get prefsWeekly => 'Weekly';

  @override
  String get prefsRarely => 'Rarely';

  @override
  String get prefsInfo =>
      'Your choice decides which tool is first on Home and the default settings for new conversions.';

  @override
  String get filterAll => 'All';

  @override
  String get filterAudio => 'Audio';

  @override
  String get filterRingtones => 'Ringtones';

  @override
  String get filterAlarms => 'Alarms';

  @override
  String get search => 'Search';

  @override
  String get searchFiles => 'Search your files';

  @override
  String get filesFooter =>
      'Copies saved to your Tunely folder in Files, kept even if you delete the app';

  @override
  String get filesNoMatch => 'No files match';

  @override
  String get justNow => 'just now';

  @override
  String get yesterday => 'yesterday';

  @override
  String metaWithDate(String meta, String date) {
    return '$meta · $date';
  }

  @override
  String metaAlarm(String duration) {
    return 'Alarm · $duration';
  }

  @override
  String metaTextTone(String duration) {
    return 'Text tone · $duration';
  }

  @override
  String get rename => 'Rename';

  @override
  String get renameTitle => 'Rename file';

  @override
  String get renameHint => 'File name';

  @override
  String get renameTaken => 'A file with that name already exists';

  @override
  String get setRingtoneAction => 'Set as ringtone';

  @override
  String get guideTitle => 'Set your ringtone';

  @override
  String guideStep(int step) {
    return 'Step $step of 3 · about 20 seconds';
  }

  @override
  String get guide1Title => 'Tap “Use as Ringtone”';

  @override
  String get guide1Body =>
      'Tap Open share menu below. Then scroll down and choose Use as Ringtone. That’s it — no GarageBand needed on iOS 26.';

  @override
  String get guideShareSave => 'Save to Files';

  @override
  String get guideShareUse => 'Use as Ringtone';

  @override
  String get guideShareAirdrop => 'AirDrop';

  @override
  String guideReady(String duration) {
    return '$duration · ready';
  }

  @override
  String get guideOpenShare => 'Open share menu';

  @override
  String get guide2Title => 'Pick it in Settings';

  @override
  String get guide2Body =>
      'Your sound is now in Settings › Sounds & Haptics › Ringtone. Tick it, or give it to one contact.';

  @override
  String get guide2Path => 'Settings › Sounds & Haptics › Ringtone';

  @override
  String get guide2Default => 'Reflection (default)';

  @override
  String get guide2Tip =>
      'Tip: set it for one person in Contacts › Edit › Ringtone.';

  @override
  String get guideOpenSettings => 'Open Settings';

  @override
  String get guide3Title => 'Done — it works!';

  @override
  String get guide3Body =>
      'Next time it takes two taps. Make alarms and text tones the same way.';

  @override
  String get guide3Card => 'All set! Ask a friend to call you to hear it.';

  @override
  String get makeAnother => 'Make another';

  @override
  String get guideGarageBandLink =>
      'On iOS 18 or older? Use the GarageBand way';

  @override
  String get guideNoFileBody =>
      'Make a ringtone first. After saving, Tunely walks you through these steps.';

  @override
  String get makeRingtone => 'Make a ringtone';

  @override
  String get next => 'Next';

  @override
  String get gbTitle => 'Set a ringtone with GarageBand';

  @override
  String get gbIntro =>
      'On iOS 18 and older, iPhone only accepts ringtones exported from GarageBand. It’s free from Apple and takes about a minute.';

  @override
  String get gbStep1 =>
      'Save your ringtone to Files with Save to Files or Share › Save to Files.';

  @override
  String get gbStep2 =>
      'Open GarageBand (free on the App Store) and start a new song with Audio Recorder.';

  @override
  String get gbStep3 =>
      'Tap the Tracks view, then the loop icon, then Files › Browse items from the Files app, and pick your ringtone.';

  @override
  String get gbStep4 =>
      'Drag it onto the track and tap the arrow at the top left › My Songs.';

  @override
  String get gbStep5 =>
      'Touch and hold the song, tap Share › Ringtone, then Export.';

  @override
  String get gbStep6 =>
      'Tap Use sound as… › Standard Ringtone. It now appears in Settings › Sounds & Haptics › Ringtone.';

  @override
  String gbStepNumber(int number) {
    return '$number';
  }

  @override
  String get helpTitle => 'Help & FAQ';

  @override
  String get helpSearch => 'Search help';

  @override
  String get helpNoResults =>
      'No answers match your search. Try another word or contact us.';

  @override
  String get mailSubject => 'Tunely support';

  @override
  String mailBody(String version, String os) {
    return 'App version: $version\niOS: $os\n\nTell us what happened:\n';
  }

  @override
  String get faqAdsQ => 'Why do I see ads?';

  @override
  String get faqAdsA =>
      'Ads keep Tunely free. You only see a short ad between tasks, after your file is already saved, never while converting. Tunely Pro removes all ads.';

  @override
  String get faqSetRingtoneQ => 'How do I set a ringtone?';

  @override
  String get faqSetRingtoneA =>
      'After you make a ringtone, tap Set as ringtone and follow the 3 steps.\n• On iOS 26: tap Share, then Use as Ringtone. Then pick it in iPhone Settings › Sounds & Haptics › Ringtone (it’s at the top).\n• On iOS 18 or older: we guide you through the free GarageBand app (Help › “Set a ringtone with GarageBand”).';

  @override
  String get faqDrmQ => 'Why can’t I convert Apple Music songs?';

  @override
  String get faqDrmA =>
      'Songs from Apple Music and other streaming services are copy-protected (DRM), so no app can convert them. Your own videos, voice memos and DRM-free music files work fine.';

  @override
  String get faqQualityQ => 'Will quality drop?';

  @override
  String get faqQualityA =>
      'Choose High (256 kbps) or Best (320 kbps) and most people can’t hear a difference. Before you convert, Tunely shows the estimated file size. If your file is already lower quality, a higher setting won’t make it better.';

  @override
  String get faqWhereSavedQ => 'Where are my files saved?';

  @override
  String get faqWhereSavedA =>
      'Every file you make appears in My files inside Tunely. When you tap Save to Files, Tunely also saves a copy to your Tunely folder in Files (iCloud Drive › Tunely by default; you choose it the first time). Copies in that folder stay even if you delete the app. Files only inside Tunely are removed if you delete the app.';

  @override
  String get faqFreeConversionsQ => 'How do free conversions work?';

  @override
  String get faqFreeConversionsA =>
      'You get 3 full-quality conversions every day, ringtones included. They reset at midnight. Failed or cancelled conversions never count. When you run out, you can watch a short ad for 1 more (up to 2 a day), wait until tomorrow, or go Pro for unlimited.';

  @override
  String get faqCancelQ => 'How do I cancel my subscription?';

  @override
  String get faqCancelA =>
      'Open Tunely Settings › Manage subscription, or iPhone Settings › [your name] › Subscriptions › Tunely Pro. If you allow notifications, we remind you a day before any free trial ends. Cancel at least 24 hours before the renewal date to avoid the next charge.';

  @override
  String get faqWhatCanIConvertQ => 'What can I convert?';

  @override
  String get faqWhatCanIConvertA =>
      'Videos from Photos or Files (MOV, MP4, M4V) and audio files (MP3, M4A, AAC, WAV, AIFF, CAF, FLAC). You can save as MP3, M4A or WAV for free, and as FLAC, AAC or OGG with Pro.';

  @override
  String get faqVideoToMp3Q => 'How do I turn a video into an MP3?';

  @override
  String get faqVideoToMp3A =>
      'On Home, tap Video to MP3 (or the big button), pick a video, check the format and quality, then tap Convert to MP3. When it’s done, tap Save to Files or Share.';

  @override
  String get faqPrivacyQ => 'Does Tunely upload my files?';

  @override
  String get faqPrivacyA =>
      'No. Everything is converted on your iPhone. Your videos and songs are never uploaded, and ads never see your files.';

  @override
  String get faqOfflineQ => 'Do I need internet?';

  @override
  String get faqOfflineA =>
      'Converting works without internet. You need internet to buy or restore Pro, to download videos stored only in iCloud, and to load ads.';

  @override
  String get faqNoAudioQ => 'Why does it say the video has no sound?';

  @override
  String get faqNoAudioA =>
      'That video has no audio track (some screen recordings and muted clips), so there’s nothing to convert. Try another video.';

  @override
  String get faqIcloudQ => 'It says “still in iCloud”. What do I do?';

  @override
  String get faqIcloudA =>
      'The video isn’t fully on your iPhone yet. Connect to Wi-Fi (or turn off Low Data Mode) and tap Try again, or open it once in Photos so it downloads.';

  @override
  String get faqConversionFailedQ => 'Converting failed. What now?';

  @override
  String get faqConversionFailedA =>
      'Tap Try compatibility mode. It works for almost every video. Your original file is never changed. If it still fails, tap Contact support; the error code is added for us automatically.';

  @override
  String get faqStorageQ => 'It says I need more space.';

  @override
  String get faqStorageA =>
      'Converting needs a little room for a temporary copy. Empty Recently Deleted in Photos, remove old files in My files, or choose Standard quality, then tap Check again.';

  @override
  String get faqBackgroundQ => 'Can I keep converting when I leave the app?';

  @override
  String get faqBackgroundA =>
      'On iOS 26, yes: it keeps going in the background. On older iOS, it may pause until you come back, and then it continues. A paused job never uses a free conversion.';

  @override
  String get faqRingtoneLengthQ => 'How long can a ringtone be?';

  @override
  String get faqRingtoneLengthA =>
      'Up to 30 seconds. Drag the handles to pick the part you like; fade in and out are added for you (you can change them).';

  @override
  String get faqAlarmTextTonesQ => 'What are alarm and text tones?';

  @override
  String get faqAlarmTextTonesA =>
      'They’re short sounds for alarms and messages. Making them is part of Tunely Pro. Ringtones are free.';

  @override
  String get faqRingtoneMissingQ => 'I can’t find my ringtone in Settings.';

  @override
  String get faqRingtoneMissingA =>
      'Make sure you finished the last step of the guide. On iOS 26 it appears at the top of Settings › Sounds & Haptics › Ringtone. On older iOS, check that you exported it from GarageBand as a ringtone.';

  @override
  String get faqTrimFadeQ => 'How do I cut or fade a song?';

  @override
  String get faqTrimFadeA =>
      'On the Convert screen, tap Trim & fade. Drag the handles or use −1 s / +1 s, set fade in and out, then tap Done.';

  @override
  String get faqMergeQ => 'How do I join songs into one?';

  @override
  String get faqMergeA =>
      'Tap Merge audio on Home (Pro), pick 2 to 10 files, drag to change the order, choose a crossfade, then tap Merge. Your original files are not changed.';

  @override
  String get faqBatchQ => 'Can I convert many files at once?';

  @override
  String get faqBatchA =>
      'Yes, with Pro: pick up to 50 files and tap Continue. Finished files are saved as they complete; if one fails, you can retry just that one.';

  @override
  String get faqVolumeBoostQ => 'What is volume boost?';

  @override
  String get faqVolumeBoostA =>
      'Pro can make quiet audio up to +6 dB louder without distortion.';

  @override
  String get faqProQ => 'What do I get with Tunely Pro?';

  @override
  String get faqProA =>
      'Unlimited conversions and ringtones, no ads, FLAC/AAC/OGG formats, batch (up to 50 files), merge audio, volume boost, and alarm and text tones.';

  @override
  String get faqTrialQ => 'How does the free trial work?';

  @override
  String get faqTrialA =>
      'If you’re eligible, Yearly starts with 3 days free. You won’t be charged until the trial ends, and you can cancel anytime before. If you’ve had a trial before, the app shows the regular price instead.';

  @override
  String get faqRestoreQ => 'I bought Pro but it’s not showing.';

  @override
  String get faqRestoreA =>
      'Tap Settings › Restore purchases. Make sure you’re signed in with the same Apple Account you used to buy. If it says “No purchases found”, check the account in iPhone Settings and try again.';

  @override
  String get faqRefundQ => 'Can I get a refund?';

  @override
  String get faqRefundA =>
      'Refunds are handled by Apple. Go to reportaproblem.apple.com and choose Tunely Pro.';

  @override
  String get faqDevicesQ => 'Does Pro work on my other devices?';

  @override
  String get faqDevicesA =>
      'Yes, on any iPhone signed in with the same Apple Account. Tap Restore purchases on the new device.';

  @override
  String get faqDeleteQ => 'Does deleting a file in Tunely delete my original?';

  @override
  String get faqDeleteA =>
      'No. Deleting removes the file from My files only. The original video in Photos and any copies you saved to your Tunely folder in Files are kept.';

  @override
  String get faqRenameQ => 'Can I rename files?';

  @override
  String get faqRenameA =>
      'Yes. In My files, tap ⋯ next to a file, then Rename.';

  @override
  String get faqFolderMissingQ => 'My Tunely folder can’t be found.';

  @override
  String get faqFolderMissingA =>
      'The folder was moved, renamed or deleted. Tap Choose folder again and pick a folder (iCloud Drive › Tunely is a good choice).';

  @override
  String get faqAccountQ => 'Do I need an account?';

  @override
  String get faqAccountA =>
      'No. Everything works without one. An account is only for invite rewards.';

  @override
  String get faqInvitesQ => 'How do invite rewards work?';

  @override
  String get faqInvitesA =>
      'Go to Settings › Invite friends, create a free account and share your link. Your friend gets a week of Pro right away (no account needed). You get a week when they make their first file.';

  @override
  String get faqInviteCodeQ => 'I have an invite code. Where do I enter it?';

  @override
  String get faqInviteCodeA =>
      'Settings › Have an invite code? If you opened your friend’s link, the code is filled in for you.';

  @override
  String get faqDeleteAccountQ => 'How do I delete my account?';

  @override
  String get faqDeleteAccountA =>
      'Settings › Account › Delete account. Your files and your Pro subscription are not affected.';

  @override
  String get faqTrackingQ => 'Why does iPhone ask about tracking?';

  @override
  String get faqTrackingA =>
      'Ad networks can show more relevant ads if you allow it. Either answer is fine, and Tunely works the same. You can change it anytime in iPhone Settings › Privacy & Security › Tracking.';

  @override
  String get faqRemoveAdsQ => 'How do I remove ads?';

  @override
  String get faqRemoveAdsA => 'Get Tunely Pro. All ads disappear right away.';

  @override
  String get faqMoreAppsQ => 'What are the app suggestions from Marberx?';

  @override
  String get faqMoreAppsA =>
      'Marberx makes Tunely and a few other small apps (like Shrink: Video Compressor). We sometimes show one that fits what you’re doing. You can hide a suggestion with ×, and nobody is paid when you install.';

  @override
  String get o1DemoFile => 'Dance_night.mov';

  @override
  String get pwBadge => 'Tunely Pro';

  @override
  String get pwHeaderRingtones => 'Unlimited ringtones, alarms & text tones';

  @override
  String get pwHeaderMp3 => 'Unlimited MP3s from all your videos';

  @override
  String get pwHeaderConvert => 'Convert every file, every format';

  @override
  String get pwBenefitRingtones => 'Unlimited ringtones';

  @override
  String get pwBenefitConversions => 'Unlimited conversions';

  @override
  String get pwBenefitFormats => 'FLAC, AAC, OGG formats';

  @override
  String get pwBenefitBatch => 'Batch 50 files at once';

  @override
  String get pwBenefitNoAds => 'No ads, merge & boost';

  @override
  String get pwToday => 'Today';

  @override
  String get pwTodayDetail => 'Full access, free';

  @override
  String pwDay(int day) {
    return 'Day $day';
  }

  @override
  String get pwReminder => 'Reminder';

  @override
  String pwStarts(String price) {
    return '$price/yr starts';
  }

  @override
  String get pwYearly => 'Yearly';

  @override
  String get pwWeekly => 'Weekly';

  @override
  String get pwLifetime => 'Lifetime';

  @override
  String pwYearlyTrial(int days, String price) {
    return '$days days free, then $price / year';
  }

  @override
  String get pwYearlyNoTrial => 'Billed every year';

  @override
  String get pwWeeklyDetail => 'Billed every week';

  @override
  String get pwLifetimeDetail => 'Pay once, yours forever';

  @override
  String pwPerWeek(String price) {
    return '$price / wk';
  }

  @override
  String pwSave(int percent) {
    return 'SAVE $percent%';
  }

  @override
  String pwTermsTrial(int days, String price) {
    return 'Free for $days days, then $price / year. Cancel anytime.';
  }

  @override
  String pwTermsYearly(String price) {
    return '$price / year. Cancel anytime.';
  }

  @override
  String pwTermsWeekly(String price) {
    return '$price / week. Cancel anytime.';
  }

  @override
  String pwTermsLifetime(String price) {
    return '$price one-time purchase. No subscription.';
  }

  @override
  String get pwCtaTrial => 'Start my free trial';

  @override
  String get pwCtaContinue => 'Continue';

  @override
  String get pwCtaLifetime => 'Buy lifetime';

  @override
  String get pwRestore => 'Restore';

  @override
  String get pwLoading => 'Loading prices from the App Store';

  @override
  String get pwUnavailable =>
      'Prices couldn\'t load. Check your connection and try again.';

  @override
  String p2FormatTitle(String feature) {
    return '$feature is a Pro format';
  }

  @override
  String p2FeatureTitle(String feature) {
    return '$feature is part of Tunely Pro';
  }

  @override
  String get p2DetailFlac => 'Lossless, studio-quality audio';

  @override
  String get p2DetailAac => 'Small files with great quality';

  @override
  String get p2DetailOgg => 'Open format for Android, games and the web';

  @override
  String get p2DetailTones => 'Custom sounds for alarms and messages';

  @override
  String get p2DetailBoost => 'Make quiet audio up to +6 dB louder';

  @override
  String get p2DetailMerge => 'Join 2 to 10 files into one';

  @override
  String get p2DetailBatch => 'Convert up to 50 files at once';

  @override
  String get p2DetailPro => 'Everything in Tunely, unlimited';

  @override
  String get p2Benefit1 => 'FLAC, AAC and OGG formats';

  @override
  String get p2Benefit2 => 'Unlimited conversions, no ads';

  @override
  String get p2Benefit3 => 'Batch up to 50 files at once';

  @override
  String p2CtaTrial(int days) {
    return 'Try Pro free for $days days';
  }

  @override
  String get p2CtaNoTrial => 'Get Tunely Pro';

  @override
  String get useMp3Free => 'Use MP3 instead (free)';

  @override
  String p3Used(int used, int total) {
    return '$used of $total free conversions used today';
  }

  @override
  String get p3Title => 'You\'re on a roll. Keep going with Pro.';

  @override
  String get p3Body =>
      'Unlimited conversions and ringtones, or come back when your free uses reset.';

  @override
  String get p3ResetsIn => 'Free uses reset in';

  @override
  String get p3Cta => 'Get unlimited';

  @override
  String get p3WatchAd => 'Watch a short ad for 1 more';

  @override
  String get p3Tomorrow => 'Come back tomorrow';

  @override
  String p4Title(int count) {
    return '$count files today — you\'re a natural';
  }

  @override
  String p4TrialDetail(int days) {
    return 'Go unlimited · $days days free';
  }

  @override
  String get p4NoTrialDetail => 'Go unlimited';

  @override
  String get p4Cta => 'Try';

  @override
  String p5Title(int count) {
    return '$count files made with Tunely';
  }

  @override
  String get p5StatMp3 => 'MP3s';

  @override
  String get p5StatTones => 'Ringtones';

  @override
  String get p5StatOther => 'Converted';

  @override
  String get p5Body =>
      'You clearly love making sounds. Yearly Pro costs less than a coffee a month.';

  @override
  String p5PlanTrial(String price, int days) {
    return '$price / year · $days days free';
  }

  @override
  String p5PlanNoTrial(String price) {
    return '$price / year';
  }

  @override
  String p5PerMonth(String price) {
    return '$price / mo';
  }

  @override
  String get p5CtaTrial => 'Start free trial';

  @override
  String get p5CtaNoTrial => 'Get Yearly';

  @override
  String get p6Eyebrow => 'One-time offer, just for today';

  @override
  String p6Off(int percent) {
    return '$percent% OFF';
  }

  @override
  String get p6Sub => 'your first year of Tunely Pro';

  @override
  String p6Price(String price) {
    return '$price / year';
  }

  @override
  String get p6EndsIn => 'Offer ends in';

  @override
  String p6Cta(int percent) {
    return 'Claim $percent% off';
  }

  @override
  String p6Terms(String intro, String price) {
    return '$intro for the first year, then $price / year. Cancel anytime.';
  }

  @override
  String get p6NoThanks => 'No thanks, continue with Free';

  @override
  String get p7Title => 'Your free trial ends tomorrow';

  @override
  String p7Body(String date) {
    return 'As promised, here\'s your reminder. Keep Pro, or cancel before $date and you won\'t be charged.';
  }

  @override
  String p7Started(String date) {
    return '$date · Trial started';
  }

  @override
  String p7StartedDetail(int count) {
    return 'You made $count files with Pro';
  }

  @override
  String get p7Today => 'Today · Reminder';

  @override
  String get p7TodayDetail => 'That\'s this message';

  @override
  String p7Charge(String date, String price) {
    return '$date · $price / year starts';
  }

  @override
  String get p7ChargeDetail => 'Renews yearly until you cancel';

  @override
  String get p7Keep => 'Keep Pro';

  @override
  String get p7Manage => 'Manage or cancel subscription';

  @override
  String get p7NotificationTitle => 'Your free trial ends tomorrow';

  @override
  String get p7NotificationBody => 'Keep Pro or cancel in two taps.';

  @override
  String get p8Eyebrow => 'Welcome back';

  @override
  String p8Title(int percent) {
    return '$percent% off Pro\nfor returning friends';
  }

  @override
  String get p8Sub => 'Your ringtones and files are still here.';

  @override
  String p8LastTone(String when) {
    return 'Your last ringtone · $when';
  }

  @override
  String p8LastFile(String when) {
    return 'Your last file · $when';
  }

  @override
  String get p8Plan => 'Yearly Pro';

  @override
  String p8PlanDetail(String price) {
    return 'First year, then $price / year';
  }

  @override
  String p8Cta(int percent) {
    return 'Get $percent% off';
  }

  @override
  String get p8Continue => 'Continue with Free';

  @override
  String get p9FailedTitle => 'Purchase didn\'t go through';

  @override
  String get p9FailedBody =>
      'The App Store declined the payment. You haven\'t been charged.';

  @override
  String get p9FailedTip =>
      'Check your payment method in Settings › Apple Account › Payment.';

  @override
  String get p9RestoredTitle => 'Welcome back to Pro';

  @override
  String get p9RestoredBody => 'Your purchase is restored on this iPhone.';

  @override
  String p9RestoredRenews(String plan, String date) {
    return '$plan · renews $date';
  }

  @override
  String get p9RestoredLifetime => 'Lifetime · yours forever';

  @override
  String get p9PendingTitle => 'Waiting for approval';

  @override
  String get p9PendingBody =>
      'Your purchase needs approval (for example Ask to Buy). Pro unlocks as soon as it\'s approved.';

  @override
  String get p9NoneTitle => 'No purchases found';

  @override
  String get p9NoneBody =>
      'No Tunely Pro purchases were found for this Apple Account. Check you are signed in with the account you used to buy.';

  @override
  String get p9OfflineTitle => 'You\'re offline';

  @override
  String get p9OfflineBody =>
      'Connect to the internet to buy or restore Pro. Converting still works without internet.';

  @override
  String get welcomePro => 'Welcome to Tunely Pro!';

  @override
  String get settingsRestore => 'Restore purchases';

  @override
  String relativeWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String relativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get batchTitle => 'Batch convert';

  @override
  String batchSummary(int done, int total, String format) {
    return '$done of $total done · $format';
  }

  @override
  String batchFormatBitrate(String format, int kbps) {
    return '$format $kbps kbps';
  }

  @override
  String batchSecondsLeft(int seconds) {
    return 'about $seconds s left';
  }

  @override
  String batchMinutesLeft(int minutes) {
    return 'about $minutes min left';
  }

  @override
  String get batchWaiting => 'Waiting';

  @override
  String get batchConverting => 'Converting…';

  @override
  String get batchCaptionContinued =>
      'On iOS 26 the batch keeps going in the background.';

  @override
  String get batchCaptionLegacy =>
      'On older iOS it may pause until you come back.';

  @override
  String get batchPaused =>
      'Paused while Tunely was in the background. It continues now.';

  @override
  String get batchStop => 'Stop';

  @override
  String get batchStopTitle => 'Stop the batch?';

  @override
  String batchStopBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count finished files are already saved.',
      one: '1 finished file is already saved.',
      zero: 'Nothing is finished yet.',
    );
    return '$_temp0 The rest won\'t be converted.';
  }

  @override
  String get batchKeepGoing => 'Keep going';

  @override
  String batchSystemTitle(int count) {
    return 'Converting $count files';
  }

  @override
  String batchSystemProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get batchNotificationTitle => 'Tunely';

  @override
  String batchNotificationBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files converted — tap to listen',
      one: '1 file converted — tap to listen',
    );
    return '$_temp0';
  }

  @override
  String batchFinishedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files converted',
      one: '1 file converted',
    );
    return '$_temp0';
  }

  @override
  String get batchView => 'View';

  @override
  String get batchFinishedTitle => 'Batch finished';

  @override
  String batchDoneChip(int count) {
    return '$count done';
  }

  @override
  String batchFailedChip(int count) {
    return '$count failed';
  }

  @override
  String batchPartialBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Finished files are already saved. Only the failed ones need another try.',
      one: 'Finished files are already saved. Only the failed one needs another try.',
    );
    return '$_temp0';
  }

  @override
  String get batchAllDoneBody => 'Every file is saved in My files.';

  @override
  String get batchStoppedBody =>
      'Stopped. Finished files are already saved in My files.';

  @override
  String get batchNeedsAttention => 'Needs attention';

  @override
  String get batchCompleted => 'Completed';

  @override
  String batchMoreFiles(int count) {
    return '$count more files';
  }

  @override
  String batchRetryFailed(int count) {
    return 'Retry failed ($count)';
  }

  @override
  String get batchOpenFiles => 'Open My files';

  @override
  String get failNoAudio => 'No audio track';

  @override
  String get failProtected => 'Protected file, can\'t be converted';

  @override
  String get failICloud => 'Still downloading from iCloud';

  @override
  String get failNoSpace => 'Not enough space on iPhone';

  @override
  String get failInterrupted => 'Interrupted before it finished';

  @override
  String get failUnreadable => 'Tunely can\'t read this file';

  @override
  String get failGeneric => 'Couldn\'t convert this file';

  @override
  String pickerSelectedCount(int count) {
    return '$count files selected';
  }

  @override
  String pickerBatchProHint(int count) {
    return 'Select up to $count files for a batch';
  }

  @override
  String pickerMergeHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can add up to $count more files',
      one: 'You can add 1 more file',
    );
    return '$_temp0';
  }

  @override
  String pickerLimitReached(int count) {
    return 'You can pick up to $count files';
  }

  @override
  String get mergeTitle => 'Merge audio';

  @override
  String get mergeAdd => 'Add';

  @override
  String mergeSummary(int count, String duration) {
    return '$count files · $duration total';
  }

  @override
  String get mergeOrderHint => 'Plays in this order · drag to reorder';

  @override
  String get mergeCrossfade => 'Crossfade between files';

  @override
  String get crossfadeOff => 'Off';

  @override
  String crossfadeSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get mergeSaveAs => 'Save as';

  @override
  String mergeButton(int count) {
    return 'Merge $count files';
  }

  @override
  String mergeCaption(int min, int max) {
    return '$min to $max files · originals are not changed';
  }

  @override
  String mergeRemove(String name) {
    return 'Remove $name';
  }

  @override
  String mergeReorder(String name) {
    return 'Reorder $name';
  }

  @override
  String get mergePreview => 'Preview the merge';

  @override
  String get mergePause => 'Pause preview';

  @override
  String get mergeOutputName => 'Tunely merge';

  @override
  String get mergeEmpty => 'Add at least 2 files to merge.';

  @override
  String mergeConvertingTitle(int count) {
    return '$count files merged into one';
  }

  @override
  String get notifyPreviewApp => 'Tunely';

  @override
  String get notifyPreviewNow => 'now';

  @override
  String get notifyPreviewBody => '8 files converted — tap to listen';

  @override
  String get notifyTitle => 'Get a ping when it\'s done';

  @override
  String get notifyBody =>
      'Big batches take a minute. Leave the app — we\'ll tell you when your files are ready. We also use this for the trial reminder we promised.';

  @override
  String get notifyTrialTitle => 'Get a reminder before your trial ends';

  @override
  String get notifyTrialBody =>
      'Allow notifications and we\'ll remind you a day before your trial ends. We also tell you when big batches are ready.';

  @override
  String get notifyTrialPreviewBody =>
      'Your trial ends tomorrow — cancel anytime in Settings';

  @override
  String get notifyTurnOn => 'Turn on notifications';

  @override
  String get ratingTitleRingtone => 'Your ringtone is ready!';

  @override
  String get ratingTitleAudio => 'Your file is ready!';

  @override
  String get ratingBody =>
      'Enjoying Tunely? A quick rating helps other people find it.';

  @override
  String get ratingRate => 'Rate on the App Store';

  @override
  String get ratingFeedback => 'Tell us what to improve';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get feedbackSubject => 'Tunely feedback';

  @override
  String get ratingThanks => 'Thanks for the rating';

  @override
  String updateVersion(String version) {
    return 'Version $version';
  }

  @override
  String get updateTitle => 'New in Tunely';

  @override
  String get updateDefaultNote => 'Improvements and bug fixes';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get milestoneEyebrow => 'Milestone unlocked';

  @override
  String get milestoneFirstRingtone => 'Your first ringtone!';

  @override
  String get milestoneFirstRingtoneBody =>
      'Your phone sounds like you now. Send it to a friend — they\'ll want one too.';

  @override
  String milestoneFiles(int count) {
    return '$count files made!';
  }

  @override
  String milestoneFilesBody(int count) {
    return 'That\'s $count files converted right on your iPhone. Share your latest one with a friend.';
  }

  @override
  String get milestoneShareRingtone => 'Share my ringtone';

  @override
  String get milestoneShareFile => 'Share my file';

  @override
  String get shareCardTitleRingtone => 'Share your ringtone';

  @override
  String get shareCardTitleFile => 'Share your file';

  @override
  String shareCardMetaRingtone(String duration) {
    return 'My new ringtone · $duration';
  }

  @override
  String shareCardMetaFile(String format, String duration) {
    return '$format · $duration';
  }

  @override
  String get shareCardMadeWith => 'Made with Tunely';

  @override
  String get shareAirDrop => 'AirDrop';

  @override
  String get shareMessages => 'Messages';

  @override
  String get shareCopyLink => 'Copy link';

  @override
  String get shareMore => 'More';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get shareCardText => 'Made with Tunely';

  @override
  String adBreakSavedAudio(String format) {
    return 'Your $format is saved';
  }

  @override
  String get adBreakSavedRingtone => 'Your ringtone is saved';

  @override
  String get adBreakBody =>
      'A short ad helps keep Tunely free. You\'ll be right back here after it.';

  @override
  String get adBreakRemoveAds => 'Remove ads with Pro';

  @override
  String get adsConsentTitle => 'Tunely is free,\nthanks to a few ads';

  @override
  String get adsConsentBetweenTasks =>
      'Ads appear only between tasks, never while converting.';

  @override
  String get adsConsentPrivate =>
      'Your files never leave your iPhone. Ads never see them.';

  @override
  String get adsConsentTracking =>
      'Next, iPhone asks if apps may track you to show more relevant ads. Either answer is fine; Tunely works the same.';

  @override
  String get adsConsentSeePro => 'Prefer no ads? See Pro';

  @override
  String get rewardedWatch => 'Watch a short ad for 1 more';

  @override
  String get rewardedEarned => '+1 free conversion today';

  @override
  String get moreAppsTitle => 'More from Marberx';

  @override
  String get moreAppsIntro =>
      'Other Marberx apps. Tap Get to open the App Store page.';

  @override
  String get moreAppsPicked => 'Picked for you';

  @override
  String get moreAppsAlso => 'Also from us';

  @override
  String get moreAppsFooter =>
      'Get opens the App Store. Soon means that app’s listing isn’t linked yet. No tracking, no rewards for installs.';

  @override
  String get moreAppsSoon => 'Soon';

  @override
  String get adLabel => 'Ad';

  @override
  String moreAppsGet(String name) {
    return 'Get $name';
  }

  @override
  String get settingsMoreApps => 'More Apps';

  @override
  String get houseCardEyebrow => 'From the makers of Tunely';

  @override
  String houseCardShrinkVideo(String size) {
    return 'That video was $size. Shrink makes videos smaller.';
  }

  @override
  String get houseCardView => 'View';

  @override
  String get houseCardHide => 'Hide this suggestion';

  @override
  String get galleryAnalytics => 'Analytics events (latest first)';

  @override
  String get galleryAnalyticsEmpty =>
      'No events yet. Use the app and come back.';

  @override
  String get galleryAnalyticsLive =>
      'Sending to Mixpanel. Check Live View in the Tunely-Dev project.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get inviteBadge => 'Both get free credits';

  @override
  String get inviteTitle => 'Invite friends, get Pro free';

  @override
  String get inviteStep1 => 'Create a free account';

  @override
  String get inviteStep2 => 'Share your personal invite link';

  @override
  String get inviteStep3 =>
      'You both receive free credits when your friend makes their first file';

  @override
  String get inviteYourLink => 'Your link';

  @override
  String get invitePrivacy =>
      'Your account only keeps your invite link and free weeks safe if you change phones. Your files never leave your iPhone.';

  @override
  String get inviteCreateAccount => 'Create free account';

  @override
  String get inviteHaveAccount => 'I already have an account';

  @override
  String get inviteSignedInBody =>
      'Your friend gets a week of Pro right away. You get a week when they make their first file.';

  @override
  String inviteCodeLine(String code) {
    return 'Code: $code';
  }

  @override
  String get copy => 'Copy';

  @override
  String get linkCopiedInvite => 'Invite link copied';

  @override
  String get statFriendsJoined => 'Friends joined';

  @override
  String get statProEarned => 'Pro earned';

  @override
  String get statPending => 'Pending';

  @override
  String statDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get inviteShare => 'Share invite link';

  @override
  String inviteShareText(String link) {
    return 'Get 1 week of Tunely Pro free with my invite: $link';
  }

  @override
  String get inviteCapReached =>
      'You\'ve reached this year\'s invite limit. Your friends still get their week.';

  @override
  String get inviteLoadFailed => 'Couldn\'t load your invite stats.';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get signUpSubtitle =>
      'Create a free account to save your invite link and rewards.';

  @override
  String get aboutTitle => 'About Us';

  @override
  String get aboutTagline => 'Convert and manage your media files easily.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutPrivacy => 'Privacy Policy';

  @override
  String get aboutTerms => 'Terms of Use';

  @override
  String get aboutContact => 'Contact Us';

  @override
  String get settingsAbout => 'About Us';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get passwordRule => 'At least 8 characters, with a number';

  @override
  String get signUpCodePreview => 'Your invite code will be';

  @override
  String get signUpCodeLater => 'Can change to a random code later';

  @override
  String get signUpCta => 'Create account';

  @override
  String get signUpTermsPrefix => 'By creating an account you agree to our ';

  @override
  String get signUpTermsAnd => ' and ';

  @override
  String get termsLink => 'Terms';

  @override
  String get privacyLink => 'Privacy Policy';

  @override
  String get signUpHaveAccount => 'Already have an account? ';

  @override
  String get signInLink => 'Sign in';

  @override
  String get emailExists => 'An account with this email already exists.';

  @override
  String get emailExistsSignIn => 'Sign in instead?';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInSubtitle =>
      'Sign in to see your invite link and free weeks.';

  @override
  String get signInError =>
      'Email or password is incorrect. Try again or reset your password.';

  @override
  String get signInLocked => 'Too many attempts. Try again in 15 minutes.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signInCta => 'Sign in';

  @override
  String get signInNew => 'New here? ';

  @override
  String get signInCreate => 'Create a free account';

  @override
  String get resetTitle => 'Reset your password';

  @override
  String get resetBody =>
      'Enter the email you signed up with. We\'ll send you a link to set a new password.';

  @override
  String get resetCta => 'Send reset link';

  @override
  String get resetSentTitle => 'Check your email';

  @override
  String get resetSentPrefix => 'If an account exists for ';

  @override
  String get resetSentSuffix =>
      ', you\'ll get a reset link in a few minutes. Check your spam folder too.';

  @override
  String get resetBack => 'Back to sign in';

  @override
  String resetResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get resetResend => 'Resend link';

  @override
  String get fieldRequired => 'Required';

  @override
  String get fieldTooLong => 'Use 50 characters or fewer';

  @override
  String get fieldEmailInvalid => 'Enter a valid email address';

  @override
  String get fieldPasswordWeak => 'At least 8 characters, with a number';

  @override
  String get accountOffline =>
      'You\'re offline. Connect to the internet and try again.';

  @override
  String get accountServerError =>
      'Something went wrong on our side. Your details are still here, try again.';

  @override
  String get accountValidationError =>
      'Please check the highlighted fields and try again.';

  @override
  String get tryAgain2 => 'Try again';

  @override
  String get accountTitle => 'Account';

  @override
  String get verifyBannerBold => 'Verify your email';

  @override
  String verifyBannerRest(String email) {
    return ' to receive your free weeks. We sent a link to $email.';
  }

  @override
  String get verifyResend => 'Resend';

  @override
  String get verifySent => 'Verification email sent';

  @override
  String get accountInviteRewards => 'Invite & rewards';

  @override
  String get accountYourCode => 'Your invite code';

  @override
  String get accountRandomCode => 'Use random code';

  @override
  String get accountRandomTitle => 'Switch to a random code?';

  @override
  String get accountRandomBody =>
      'Your current code and link stop working for new friends. You can only do this once.';

  @override
  String get accountRandomConfirm => 'Switch';

  @override
  String get accountFreeEarned => 'Free Pro earned';

  @override
  String get accountInvite => 'Invite friends';

  @override
  String get accountSecurity => 'Security';

  @override
  String get accountChangePassword => 'Change password';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutBody =>
      'Tunely keeps working and your Pro is not affected. Sign in again any time to see your invites.';

  @override
  String get accountProNote =>
      'Your Pro subscription is linked to your Apple ID, not this account. Manage it in Settings › Apple ID › Subscriptions.';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get fieldCurrentPassword => 'Current password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get changePasswordWrong => 'That password is not right';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get deleteTitle2 => 'Delete your account?';

  @override
  String get deleteGone => 'Permanently deleted';

  @override
  String deleteGoneAccount(String name, String email) {
    return 'Your account ($name, $email)';
  }

  @override
  String deleteGoneCode(String code) {
    return 'Your invite code $code and link';
  }

  @override
  String get deleteGoneDays => 'Free Pro weeks not yet used';

  @override
  String get deleteKept => 'Not affected';

  @override
  String get deleteKeptFiles =>
      'Your files in Tunely and in your Tunely folder';

  @override
  String get deleteKeptPro =>
      'Your Pro subscription — cancel it separately in Settings › Apple ID › Subscriptions';

  @override
  String get deletePasswordLabel => 'Enter your password to confirm';

  @override
  String get deleteKeep => 'Keep my account';

  @override
  String get deleteDone => 'Your account was deleted';

  @override
  String get redeemTitle => 'Have an invite code?';

  @override
  String get redeemBody =>
      'Enter a friend\'s code to get 1 week of Pro free. No account needed.';

  @override
  String get redeemLabel => 'Invite code';

  @override
  String get redeemFromLink => 'Added from your friend\'s link';

  @override
  String get redeemInvalid =>
      'This code isn\'t valid, or an invite was already used on this iPhone.';

  @override
  String get redeemValidCode => 'Valid invite code';

  @override
  String get redeemInvalidCode => 'Invalid invite code';

  @override
  String get redeemCodeMaxLength =>
      'Invite code can contain a maximum of 10 characters.';

  @override
  String get redeemCta => 'Apply code';

  @override
  String get redeemSkip => 'Skip';

  @override
  String get redeemSuccessTitle => '1 week of Pro unlocked';

  @override
  String redeemSuccessBody(String name, String date) {
    return 'A gift from $name. Enjoy unlimited conversions, all formats and merge until $date.';
  }

  @override
  String redeemSuccessHint(String name) {
    return 'Make your first file and $name gets a free week too.';
  }

  @override
  String get redeemAlreadyPro =>
      'You\'re already Pro — your friend still gets their reward when you make your first file.';

  @override
  String get redeemMakeFile => 'Make a file';

  @override
  String get redeemFriend => 'your friend';

  @override
  String get settingsAccountSignedOut => 'Sign in or create account';

  @override
  String get settingsAccountOptional => 'Optional · only for invite rewards';

  @override
  String get settingsInvite => 'Invite friends';

  @override
  String get settingsInviteDetail => 'Free credits';

  @override
  String get settingsHaveCode => 'Have an invite code?';

  @override
  String get onboardingInviteCode => 'Got an invite code?';
}
