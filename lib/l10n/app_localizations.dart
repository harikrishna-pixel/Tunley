import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabFiles.
  ///
  /// In en, this message translates to:
  /// **'My files'**
  String get tabFiles;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tunely'**
  String get homeTitle;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// No description provided for @proChip.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proChip;

  /// No description provided for @freeCounter.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} free today'**
  String freeCounter(int remaining, int total);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get galleryTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @showToast.
  ///
  /// In en, this message translates to:
  /// **'Show toast'**
  String get showToast;

  /// No description provided for @toastSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved on this iPhone'**
  String get toastSaved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @showSheet.
  ///
  /// In en, this message translates to:
  /// **'Show sheet'**
  String get showSheet;

  /// No description provided for @showDialog.
  ///
  /// In en, this message translates to:
  /// **'Show dialog'**
  String get showDialog;

  /// No description provided for @sheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Trim and fade'**
  String get sheetTitle;

  /// No description provided for @sheetBody.
  ///
  /// In en, this message translates to:
  /// **'Drag the handles to keep the best part.'**
  String get sheetBody;

  /// No description provided for @dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop converting?'**
  String get dialogTitle;

  /// No description provided for @dialogBody.
  ///
  /// In en, this message translates to:
  /// **'The original file stays unchanged.'**
  String get dialogBody;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @audioFile.
  ///
  /// In en, this message translates to:
  /// **'Audio file'**
  String get audioFile;

  /// No description provided for @ringtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get ringtone;

  /// No description provided for @highQuality.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highQuality;

  /// No description provided for @highQualityDetail.
  ///
  /// In en, this message translates to:
  /// **'256 kbps'**
  String get highQualityDetail;

  /// No description provided for @sizeEstimate.
  ///
  /// In en, this message translates to:
  /// **'1.3 MB'**
  String get sizeEstimate;

  /// No description provided for @originalSafe.
  ///
  /// In en, this message translates to:
  /// **'Your original file is safe and unchanged'**
  String get originalSafe;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a ringtone from any video'**
  String get heroTitle;

  /// No description provided for @heroButton.
  ///
  /// In en, this message translates to:
  /// **'Choose a video'**
  String get heroButton;

  /// No description provided for @playerTitle.
  ///
  /// In en, this message translates to:
  /// **'Summer concert'**
  String get playerTitle;

  /// No description provided for @playerMeta.
  ///
  /// In en, this message translates to:
  /// **'MP3 · 256 kbps · 1.3 MB'**
  String get playerMeta;

  /// No description provided for @playerElapsed.
  ///
  /// In en, this message translates to:
  /// **'0:12'**
  String get playerElapsed;

  /// No description provided for @playerDuration.
  ///
  /// In en, this message translates to:
  /// **'3:05'**
  String get playerDuration;

  /// No description provided for @toolVideo.
  ///
  /// In en, this message translates to:
  /// **'Video to MP3'**
  String get toolVideo;

  /// No description provided for @toolConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get toolConvert;

  /// No description provided for @toolTrim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get toolTrim;

  /// No description provided for @trialToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get trialToday;

  /// No description provided for @trialDay2.
  ///
  /// In en, this message translates to:
  /// **'Day 2'**
  String get trialDay2;

  /// No description provided for @trialDay3.
  ///
  /// In en, this message translates to:
  /// **'Day 3'**
  String get trialDay3;

  /// No description provided for @trialStart.
  ///
  /// In en, this message translates to:
  /// **'Start your plan'**
  String get trialStart;

  /// No description provided for @trialReminder.
  ///
  /// In en, this message translates to:
  /// **'We remind you'**
  String get trialReminder;

  /// No description provided for @trialCharge.
  ///
  /// In en, this message translates to:
  /// **'Plan continues'**
  String get trialCharge;

  /// No description provided for @galleryButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get galleryButtons;

  /// No description provided for @gallerySegmented.
  ///
  /// In en, this message translates to:
  /// **'Segmented control'**
  String get gallerySegmented;

  /// No description provided for @galleryFormats.
  ///
  /// In en, this message translates to:
  /// **'Format chips'**
  String get galleryFormats;

  /// No description provided for @galleryQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get galleryQuality;

  /// No description provided for @galleryTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get galleryTools;

  /// No description provided for @galleryBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get galleryBadges;

  /// No description provided for @galleryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get galleryStatus;

  /// No description provided for @galleryHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get galleryHero;

  /// No description provided for @galleryPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get galleryPlayer;

  /// No description provided for @galleryWaveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform'**
  String get galleryWaveform;

  /// No description provided for @galleryTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial timeline'**
  String get galleryTrial;

  /// No description provided for @galleryOverlays.
  ///
  /// In en, this message translates to:
  /// **'Toast, sheet, dialog'**
  String get galleryOverlays;

  /// No description provided for @formatMp3.
  ///
  /// In en, this message translates to:
  /// **'MP3'**
  String get formatMp3;

  /// No description provided for @formatM4a.
  ///
  /// In en, this message translates to:
  /// **'M4A'**
  String get formatM4a;

  /// No description provided for @formatFlac.
  ///
  /// In en, this message translates to:
  /// **'FLAC'**
  String get formatFlac;

  /// No description provided for @formatWav.
  ///
  /// In en, this message translates to:
  /// **'WAV'**
  String get formatWav;

  /// No description provided for @formatOgg.
  ///
  /// In en, this message translates to:
  /// **'OGG'**
  String get formatOgg;

  /// No description provided for @formatM4r.
  ///
  /// In en, this message translates to:
  /// **'M4R'**
  String get formatM4r;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @waveformRange.
  ///
  /// In en, this message translates to:
  /// **'Selected range'**
  String get waveformRange;

  /// No description provided for @formatAac.
  ///
  /// In en, this message translates to:
  /// **'AAC'**
  String get formatAac;

  /// No description provided for @engineDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio engine'**
  String get engineDebugTitle;

  /// No description provided for @enginePickVideo.
  ///
  /// In en, this message translates to:
  /// **'Pick a video'**
  String get enginePickVideo;

  /// No description provided for @enginePickAudio.
  ///
  /// In en, this message translates to:
  /// **'Pick an audio file'**
  String get enginePickAudio;

  /// No description provided for @engineConvertAll.
  ///
  /// In en, this message translates to:
  /// **'Convert to every format'**
  String get engineConvertAll;

  /// No description provided for @engineChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Tunely folder'**
  String get engineChooseFolder;

  /// No description provided for @engineCopyToFolder.
  ///
  /// In en, this message translates to:
  /// **'Save to folder'**
  String get engineCopyToFolder;

  /// No description provided for @engineSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {folder} as {name}'**
  String engineSavedTo(String folder, String name);

  /// No description provided for @engineInfo.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s · {sampleRate} Hz · {channels} ch · {bitrate}'**
  String engineInfo(
    String seconds,
    int sampleRate,
    int channels,
    String bitrate,
  );

  /// No description provided for @engineBitrate.
  ///
  /// In en, this message translates to:
  /// **'{kbps} kbps'**
  String engineBitrate(int kbps);

  /// No description provided for @engineBitrateUnknown.
  ///
  /// In en, this message translates to:
  /// **'bitrate unknown'**
  String get engineBitrateUnknown;

  /// No description provided for @engineNoAudio.
  ///
  /// In en, this message translates to:
  /// **'This video has no sound'**
  String get engineNoAudio;

  /// No description provided for @engineProtected.
  ///
  /// In en, this message translates to:
  /// **'This file is copy-protected'**
  String get engineProtected;

  /// No description provided for @engineResult.
  ///
  /// In en, this message translates to:
  /// **'{format} · {size} · {seconds} s'**
  String engineResult(String format, String size, String seconds);

  /// No description provided for @engineFailed.
  ///
  /// In en, this message translates to:
  /// **'{format} failed: {code}'**
  String engineFailed(String format, String code);

  /// No description provided for @engineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{format} encoder not bundled'**
  String engineUnavailable(String format);

  /// No description provided for @engineFreeSpace.
  ///
  /// In en, this message translates to:
  /// **'Free space: {size}'**
  String engineFreeSpace(String size);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @heroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your favourite tool'**
  String get heroEyebrow;

  /// No description provided for @heroTitleRingtone.
  ///
  /// In en, this message translates to:
  /// **'Make a ringtone from any video'**
  String get heroTitleRingtone;

  /// No description provided for @heroTitleMp3.
  ///
  /// In en, this message translates to:
  /// **'Turn any video into an MP3'**
  String get heroTitleMp3;

  /// No description provided for @heroTitleConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert audio to any format'**
  String get heroTitleConvert;

  /// No description provided for @heroCtaRingtone.
  ///
  /// In en, this message translates to:
  /// **'Choose a video or song'**
  String get heroCtaRingtone;

  /// No description provided for @heroCtaMp3.
  ///
  /// In en, this message translates to:
  /// **'Choose a video'**
  String get heroCtaMp3;

  /// No description provided for @heroCtaConvert.
  ///
  /// In en, this message translates to:
  /// **'Choose an audio file'**
  String get heroCtaConvert;

  /// No description provided for @homeTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get homeTools;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @toolVideoToMp3.
  ///
  /// In en, this message translates to:
  /// **'Video to MP3'**
  String get toolVideoToMp3;

  /// No description provided for @toolConvertFormat.
  ///
  /// In en, this message translates to:
  /// **'Convert format'**
  String get toolConvertFormat;

  /// No description provided for @toolTrimFade.
  ///
  /// In en, this message translates to:
  /// **'Trim & fade'**
  String get toolTrimFade;

  /// No description provided for @toolMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge audio'**
  String get toolMerge;

  /// No description provided for @toolBoost.
  ///
  /// In en, this message translates to:
  /// **'Volume boost'**
  String get toolBoost;

  /// No description provided for @toolBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch convert'**
  String get toolBatch;

  /// No description provided for @metaFormatBitrateSize.
  ///
  /// In en, this message translates to:
  /// **'{format} · {kbps} kbps · {size}'**
  String metaFormatBitrateSize(String format, int kbps, String size);

  /// No description provided for @metaFormatSize.
  ///
  /// In en, this message translates to:
  /// **'{format} · {size}'**
  String metaFormatSize(String format, String size);

  /// No description provided for @metaRingtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone · {duration}'**
  String metaRingtone(String duration);

  /// No description provided for @toneRingtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get toneRingtone;

  /// No description provided for @toneAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get toneAlarm;

  /// No description provided for @toneTextTone.
  ///
  /// In en, this message translates to:
  /// **'Text tone'**
  String get toneTextTone;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get pickerTitle;

  /// No description provided for @pickerVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get pickerVideos;

  /// No description provided for @pickerAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio files'**
  String get pickerAudio;

  /// No description provided for @pickerRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get pickerRecent;

  /// No description provided for @pickerChooseVideos.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get pickerChooseVideos;

  /// No description provided for @pickerBrowseFiles.
  ///
  /// In en, this message translates to:
  /// **'Browse Files'**
  String get pickerBrowseFiles;

  /// No description provided for @pickerBrowseFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick audio from Files, iCloud Drive or other apps'**
  String get pickerBrowseFilesHint;

  /// No description provided for @pickerVideosHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a video from your library. Tunely only sees the videos you choose.'**
  String get pickerVideosHint;

  /// No description provided for @pickerRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your converted files will show up here.'**
  String get pickerRecentEmpty;

  /// No description provided for @pickerVideoSelected.
  ///
  /// In en, this message translates to:
  /// **'1 video selected · {duration}'**
  String pickerVideoSelected(String duration);

  /// No description provided for @pickerAudioSelected.
  ///
  /// In en, this message translates to:
  /// **'1 audio file selected'**
  String get pickerAudioSelected;

  /// No description provided for @pickerNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Nothing selected yet'**
  String get pickerNothingSelected;

  /// No description provided for @pickerBatchHint.
  ///
  /// In en, this message translates to:
  /// **'Batch up to 50 files with Pro'**
  String get pickerBatchHint;

  /// No description provided for @pickerOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'Open Files'**
  String get pickerOpenFiles;

  /// No description provided for @pickerLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting your file ready'**
  String get pickerLoading;

  /// No description provided for @sourceVideoMeta.
  ///
  /// In en, this message translates to:
  /// **'Video · {duration} · {size}'**
  String sourceVideoMeta(String duration, String size);

  /// No description provided for @sourceAudioMeta.
  ///
  /// In en, this message translates to:
  /// **'{format} · {duration} · {size}'**
  String sourceAudioMeta(String format, String duration, String size);

  /// No description provided for @convertTitleAudio.
  ///
  /// In en, this message translates to:
  /// **'Convert to audio'**
  String get convertTitleAudio;

  /// No description provided for @convertTitleRingtone.
  ///
  /// In en, this message translates to:
  /// **'Make a ringtone'**
  String get convertTitleRingtone;

  /// No description provided for @convertFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get convertFormat;

  /// No description provided for @convertQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get convertQuality;

  /// No description provided for @qualityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get qualityStandard;

  /// No description provided for @qualityStandardDetail.
  ///
  /// In en, this message translates to:
  /// **'128 kbps · voice, podcasts'**
  String get qualityStandardDetail;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qualityHigh;

  /// No description provided for @qualityHighDetail.
  ///
  /// In en, this message translates to:
  /// **'256 kbps · music (recommended)'**
  String get qualityHighDetail;

  /// No description provided for @qualityBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get qualityBest;

  /// No description provided for @qualityBestDetail.
  ///
  /// In en, this message translates to:
  /// **'320 kbps · same as the original'**
  String get qualityBestDetail;

  /// No description provided for @qualityLossless.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get qualityLossless;

  /// No description provided for @qualityWavDetail.
  ///
  /// In en, this message translates to:
  /// **'Uncompressed · 16-bit, 44.1 kHz'**
  String get qualityWavDetail;

  /// No description provided for @qualityFlacDetail.
  ///
  /// In en, this message translates to:
  /// **'Compressed without losing quality'**
  String get qualityFlacDetail;

  /// No description provided for @trimFade.
  ///
  /// In en, this message translates to:
  /// **'Trim & fade'**
  String get trimFade;

  /// No description provided for @trimSummaryFull.
  ///
  /// In en, this message translates to:
  /// **'Full {duration}'**
  String trimSummaryFull(String duration);

  /// No description provided for @trimSummaryRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String trimSummaryRange(String start, String end);

  /// No description provided for @fadeNone.
  ///
  /// In en, this message translates to:
  /// **'No fade'**
  String get fadeNone;

  /// No description provided for @fadeInOnly.
  ///
  /// In en, this message translates to:
  /// **'Fade in'**
  String get fadeInOnly;

  /// No description provided for @fadeOutOnly.
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeOutOnly;

  /// No description provided for @fadeBoth.
  ///
  /// In en, this message translates to:
  /// **'Fade in & out'**
  String get fadeBoth;

  /// No description provided for @trimSummary.
  ///
  /// In en, this message translates to:
  /// **'{range} · {fade}'**
  String trimSummary(String range, String fade);

  /// No description provided for @summaryLossy.
  ///
  /// In en, this message translates to:
  /// **'{format} · {kbps} kbps · {duration}'**
  String summaryLossy(String format, int kbps, String duration);

  /// No description provided for @summaryLossless.
  ///
  /// In en, this message translates to:
  /// **'{format} · {duration}'**
  String summaryLossless(String format, String duration);

  /// No description provided for @summarySize.
  ///
  /// In en, this message translates to:
  /// **'{estimate} (from {source})'**
  String summarySize(String estimate, String source);

  /// No description provided for @summaryRingtone.
  ///
  /// In en, this message translates to:
  /// **'M4R ringtone · {seconds} s'**
  String summaryRingtone(int seconds);

  /// No description provided for @readyForIphone.
  ///
  /// In en, this message translates to:
  /// **'Ready for iPhone'**
  String get readyForIphone;

  /// No description provided for @convertCta.
  ///
  /// In en, this message translates to:
  /// **'Convert to {format}'**
  String convertCta(String format);

  /// No description provided for @createRingtone.
  ///
  /// In en, this message translates to:
  /// **'Create ringtone'**
  String get createRingtone;

  /// No description provided for @selectedPart.
  ///
  /// In en, this message translates to:
  /// **'Selected part'**
  String get selectedPart;

  /// No description provided for @selectedRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} · {seconds} s'**
  String selectedRange(String start, String end, int seconds);

  /// No description provided for @selectedRangeLong.
  ///
  /// In en, this message translates to:
  /// **'Selected {start} – {end} · {seconds} s'**
  String selectedRangeLong(String start, String end, int seconds);

  /// No description provided for @fadeIn.
  ///
  /// In en, this message translates to:
  /// **'Fade in'**
  String get fadeIn;

  /// No description provided for @fadeOut.
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeOut;

  /// No description provided for @fadeSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String fadeSeconds(int seconds);

  /// No description provided for @volumeBoost.
  ///
  /// In en, this message translates to:
  /// **'Volume boost'**
  String get volumeBoost;

  /// No description provided for @volumeBoostDetail.
  ///
  /// In en, this message translates to:
  /// **'Pro · up to +{db} dB'**
  String volumeBoostDetail(int db);

  /// No description provided for @volumeBoostDetailPro.
  ///
  /// In en, this message translates to:
  /// **'Up to +{db} dB'**
  String volumeBoostDetailPro(int db);

  /// No description provided for @ringtoneInfo.
  ///
  /// In en, this message translates to:
  /// **'iPhone ringtones can be up to {seconds} seconds. After saving we\'ll guide you step by step to set it.'**
  String ringtoneInfo(int seconds);

  /// No description provided for @minusOneSecond.
  ///
  /// In en, this message translates to:
  /// **'−1 s'**
  String get minusOneSecond;

  /// No description provided for @plusOneSecond.
  ///
  /// In en, this message translates to:
  /// **'+1 s'**
  String get plusOneSecond;

  /// No description provided for @minusOneSecondLabel.
  ///
  /// In en, this message translates to:
  /// **'Back 1 second'**
  String get minusOneSecondLabel;

  /// No description provided for @plusOneSecondLabel.
  ///
  /// In en, this message translates to:
  /// **'Forward 1 second'**
  String get plusOneSecondLabel;

  /// No description provided for @convertingTitle.
  ///
  /// In en, this message translates to:
  /// **'Converting'**
  String get convertingTitle;

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'about {seconds} s left'**
  String secondsLeft(int seconds);

  /// No description provided for @almostDone.
  ///
  /// In en, this message translates to:
  /// **'almost done'**
  String get almostDone;

  /// No description provided for @convertingFile.
  ///
  /// In en, this message translates to:
  /// **'{source} → {format}'**
  String convertingFile(String source, String format);

  /// No description provided for @convertingMeta.
  ///
  /// In en, this message translates to:
  /// **'{kbps} kbps · {size}'**
  String convertingMeta(int kbps, String size);

  /// No description provided for @convertingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Converting on your iPhone · nothing is uploaded'**
  String get convertingPrivacy;

  /// No description provided for @runInBackground.
  ///
  /// In en, this message translates to:
  /// **'Run in background'**
  String get runInBackground;

  /// No description provided for @backgroundCaption.
  ///
  /// In en, this message translates to:
  /// **'On iOS 26 it keeps going. On older iOS it may pause until you come back.'**
  String get backgroundCaption;

  /// No description provided for @stopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop converting?'**
  String get stopTitle;

  /// No description provided for @stopBody.
  ///
  /// In en, this message translates to:
  /// **'The original file stays unchanged. Nothing is saved and it doesn\'t use a free conversion.'**
  String get stopBody;

  /// No description provided for @stopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopConfirm;

  /// No description provided for @keepConverting.
  ///
  /// In en, this message translates to:
  /// **'Keep converting'**
  String get keepConverting;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get resultTitle;

  /// No description provided for @resultReadyAudio.
  ///
  /// In en, this message translates to:
  /// **'Your {format} is ready'**
  String resultReadyAudio(String format);

  /// No description provided for @resultReadyRingtone.
  ///
  /// In en, this message translates to:
  /// **'Your ringtone is ready'**
  String get resultReadyRingtone;

  /// No description provided for @resultSubAudio.
  ///
  /// In en, this message translates to:
  /// **'Converted on your iPhone · nothing uploaded'**
  String get resultSubAudio;

  /// No description provided for @resultSubRingtone.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds · {fade}'**
  String resultSubRingtone(int seconds, String fade);

  /// No description provided for @fadeBothLower.
  ///
  /// In en, this message translates to:
  /// **'fade in and out'**
  String get fadeBothLower;

  /// No description provided for @fadeInLower.
  ///
  /// In en, this message translates to:
  /// **'fade in'**
  String get fadeInLower;

  /// No description provided for @fadeOutLower.
  ///
  /// In en, this message translates to:
  /// **'fade out'**
  String get fadeOutLower;

  /// No description provided for @noFadeLower.
  ///
  /// In en, this message translates to:
  /// **'no fade'**
  String get noFadeLower;

  /// No description provided for @resultMetaRingtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone · M4R · {duration}'**
  String resultMetaRingtone(String duration);

  /// No description provided for @statVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get statVideo;

  /// No description provided for @statAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get statAudio;

  /// No description provided for @statTook.
  ///
  /// In en, this message translates to:
  /// **'Took'**
  String get statTook;

  /// No description provided for @makeItRingtone.
  ///
  /// In en, this message translates to:
  /// **'Make it a ringtone'**
  String get makeItRingtone;

  /// No description provided for @makeItRingtoneDetail.
  ///
  /// In en, this message translates to:
  /// **'Pick the best {seconds} seconds'**
  String makeItRingtoneDetail(int seconds);

  /// No description provided for @alsoSaveMp3.
  ///
  /// In en, this message translates to:
  /// **'Also save as MP3'**
  String get alsoSaveMp3;

  /// No description provided for @alsoSaveMp3Detail.
  ///
  /// In en, this message translates to:
  /// **'Keep a copy to share or play anywhere'**
  String get alsoSaveMp3Detail;

  /// No description provided for @saveToFiles.
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get saveToFiles;

  /// No description provided for @setAsRingtone.
  ///
  /// In en, this message translates to:
  /// **'Set as ringtone'**
  String get setAsRingtone;

  /// No description provided for @freeLeftLine.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} free conversions left today'**
  String freeLeftLine(int remaining, int total);

  /// No description provided for @goUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Go unlimited'**
  String get goUnlimited;

  /// No description provided for @savedToFolder.
  ///
  /// In en, this message translates to:
  /// **'Saved to Files › {folder}'**
  String savedToFolder(String folder);

  /// No description provided for @folderGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'We can\'t find your Tunely folder'**
  String get folderGoneTitle;

  /// No description provided for @folderGoneBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been moved or deleted. Your file is still in My files.'**
  String get folderGoneBody;

  /// No description provided for @chooseFolderAgain.
  ///
  /// In en, this message translates to:
  /// **'Choose folder again'**
  String get chooseFolderAgain;

  /// No description provided for @jobReady.
  ///
  /// In en, this message translates to:
  /// **'Your {format} is ready'**
  String jobReady(String format);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @jobFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t convert this file'**
  String get jobFailedToast;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @proGateTitle.
  ///
  /// In en, this message translates to:
  /// **'{feature} is part of Tunely Pro'**
  String proGateTitle(String feature);

  /// No description provided for @proGateBody.
  ///
  /// In en, this message translates to:
  /// **'Pro unlocks every format, alarms and text tones, volume boost, merge, batch and unlimited conversions. No ads.'**
  String get proGateBody;

  /// No description provided for @proGateCta.
  ///
  /// In en, this message translates to:
  /// **'See Tunely Pro'**
  String get proGateCta;

  /// No description provided for @useMp3Instead.
  ///
  /// In en, this message translates to:
  /// **'Use MP3 instead'**
  String get useMp3Instead;

  /// No description provided for @featureFormat.
  ///
  /// In en, this message translates to:
  /// **'{format}'**
  String featureFormat(String format);

  /// No description provided for @limitTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s {total} free conversions'**
  String limitTitle(int total);

  /// No description provided for @limitBody.
  ///
  /// In en, this message translates to:
  /// **'New free conversions arrive at midnight. Your file is still here when you come back.'**
  String get limitBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @errorUnreadableTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t convert this file'**
  String get errorUnreadableTitle;

  /// No description provided for @errorUnreadableBody.
  ///
  /// In en, this message translates to:
  /// **'The file may be damaged or in a format we can\'t read.'**
  String get errorUnreadableBody;

  /// No description provided for @errorNoAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'This video has no sound'**
  String get errorNoAudioTitle;

  /// No description provided for @errorNoAudioBody.
  ///
  /// In en, this message translates to:
  /// **'There\'s no audio track to turn into a file. Try a different video.'**
  String get errorNoAudioBody;

  /// No description provided for @errorProtectedTitle.
  ///
  /// In en, this message translates to:
  /// **'This file is copy-protected'**
  String get errorProtectedTitle;

  /// No description provided for @errorProtectedBody.
  ///
  /// In en, this message translates to:
  /// **'Purchased or rented videos and songs can\'t be converted.'**
  String get errorProtectedBody;

  /// No description provided for @errorIcloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download from iCloud'**
  String get errorIcloudTitle;

  /// No description provided for @errorIcloudBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get errorIcloudBody;

  /// No description provided for @errorNoSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on your iPhone'**
  String get errorNoSpaceTitle;

  /// No description provided for @errorNoSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Free up {mb} MB and try again.'**
  String errorNoSpaceBody(int mb);

  /// No description provided for @errorNoSpaceBodyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Free up some space and try again.'**
  String get errorNoSpaceBodyGeneric;

  /// No description provided for @errorSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file'**
  String get errorSaveTitle;

  /// No description provided for @errorSaveBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while writing the file.'**
  String get errorSaveBody;

  /// No description provided for @errorInterruptedTitle.
  ///
  /// In en, this message translates to:
  /// **'The conversion was interrupted'**
  String get errorInterruptedTitle;

  /// No description provided for @errorInterruptedBody.
  ///
  /// In en, this message translates to:
  /// **'iOS paused Tunely before it finished. Nothing was counted.'**
  String get errorInterruptedBody;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'Code {code}'**
  String errorCode(String code);

  /// No description provided for @sourceBitrateCaption.
  ///
  /// In en, this message translates to:
  /// **'Source is {kbps} kbps. Higher won\'t improve it.'**
  String sourceBitrateCaption(int kbps);

  /// No description provided for @e1Title.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t convert {name}'**
  String e1Title(String name);

  /// No description provided for @e1Body.
  ///
  /// In en, this message translates to:
  /// **'It stopped at {percent}%. This sometimes happens with screen recordings that use a variable frame rate.'**
  String e1Body(int percent);

  /// No description provided for @e1BodyNoProgress.
  ///
  /// In en, this message translates to:
  /// **'This sometimes happens with screen recordings that use a variable frame rate.'**
  String get e1BodyNoProgress;

  /// No description provided for @e1CardLabel.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get e1CardLabel;

  /// No description provided for @e1Card.
  ///
  /// In en, this message translates to:
  /// **'Try again in compatibility mode (AAC). It works for almost every video. Error code {code} is attached if you contact us.'**
  String e1Card(String code);

  /// No description provided for @e1CardRetried.
  ///
  /// In en, this message translates to:
  /// **'Compatibility mode couldn\'t read this file either. Error code {code} is attached if you contact us.'**
  String e1CardRetried(String code);

  /// No description provided for @e1Cta.
  ///
  /// In en, this message translates to:
  /// **'Try compatibility mode'**
  String get e1Cta;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @supportCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {email} and the error code'**
  String supportCopied(String email);

  /// No description provided for @e2Title.
  ///
  /// In en, this message translates to:
  /// **'Free up {mb} MB to continue'**
  String e2Title(int mb);

  /// No description provided for @e2Body.
  ///
  /// In en, this message translates to:
  /// **'Converting needs a little room for a temporary copy. It\'s deleted as soon as the file is ready.'**
  String get e2Body;

  /// No description provided for @e2CardLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick ways to make room'**
  String get e2CardLabel;

  /// No description provided for @e2Tip1.
  ///
  /// In en, this message translates to:
  /// **'Empty Recently Deleted in Photos'**
  String get e2Tip1;

  /// No description provided for @e2Tip2.
  ///
  /// In en, this message translates to:
  /// **'Remove old files in My files'**
  String get e2Tip2;

  /// No description provided for @e2Tip3.
  ///
  /// In en, this message translates to:
  /// **'Choose Standard quality (smaller file)'**
  String get e2Tip3;

  /// No description provided for @e2Cta.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get e2Cta;

  /// No description provided for @e2Help.
  ///
  /// In en, this message translates to:
  /// **'How to free up space'**
  String get e2Help;

  /// No description provided for @e2HelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to free up space'**
  String get e2HelpTitle;

  /// No description provided for @e2HelpBody.
  ///
  /// In en, this message translates to:
  /// **'Open Settings › General › iPhone Storage to see what uses the most space. Offloading unused apps keeps their data, and emptying Recently Deleted in Photos frees space right away.'**
  String get e2HelpBody;

  /// No description provided for @e2StillShort.
  ///
  /// In en, this message translates to:
  /// **'Still {mb} MB short'**
  String e2StillShort(int mb);

  /// No description provided for @e3Title.
  ///
  /// In en, this message translates to:
  /// **'This video is still in iCloud'**
  String get e3Title;

  /// No description provided for @e3Body.
  ///
  /// In en, this message translates to:
  /// **'Tunely couldn\'t download {name} from iCloud. Check your connection, or open it once in Photos so it downloads.'**
  String e3Body(String name);

  /// No description provided for @e3BodyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Tunely couldn\'t download this file from iCloud. Check your connection, or open it once in Photos so it downloads.'**
  String get e3BodyGeneric;

  /// No description provided for @e3CardLabel.
  ///
  /// In en, this message translates to:
  /// **'Size to download'**
  String get e3CardLabel;

  /// No description provided for @e3Card.
  ///
  /// In en, this message translates to:
  /// **'{size} over Wi-Fi or mobile data'**
  String e3Card(String size);

  /// No description provided for @pickAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Pick another file'**
  String get pickAnotherFile;

  /// No description provided for @e4TitleSong.
  ///
  /// In en, this message translates to:
  /// **'This song is copy-protected'**
  String get e4TitleSong;

  /// No description provided for @e4TitleVideo.
  ///
  /// In en, this message translates to:
  /// **'This video is copy-protected'**
  String get e4TitleVideo;

  /// No description provided for @e4Body.
  ///
  /// In en, this message translates to:
  /// **'Songs from Apple Music and other streaming services are protected, so no app can convert them. Your own videos, voice memos and DRM-free music files work fine.'**
  String get e4Body;

  /// No description provided for @e4CardLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get e4CardLabel;

  /// No description provided for @e4Card.
  ///
  /// In en, this message translates to:
  /// **'{name} · .{ext}'**
  String e4Card(String name, String ext);

  /// No description provided for @whatCanIConvert.
  ///
  /// In en, this message translates to:
  /// **'What can I convert?'**
  String get whatCanIConvert;

  /// No description provided for @convertibleTitle.
  ///
  /// In en, this message translates to:
  /// **'What Tunely can convert'**
  String get convertibleTitle;

  /// No description provided for @convertibleBody.
  ///
  /// In en, this message translates to:
  /// **'Videos you recorded or saved (MOV, MP4, M4V), voice memos and DRM-free audio (MP3, M4A, WAV, AIFF, CAF, FLAC, AAC). Purchased or streamed songs and rented videos are copy-protected.'**
  String get convertibleBody;

  /// No description provided for @e4bTitle.
  ///
  /// In en, this message translates to:
  /// **'This video has no sound'**
  String get e4bTitle;

  /// No description provided for @e4bBody.
  ///
  /// In en, this message translates to:
  /// **'There\'s no audio track in this video, so there\'s nothing to convert. Try another video, or check the sound wasn\'t muted when it was recorded.'**
  String get e4bBody;

  /// No description provided for @e4bCard.
  ///
  /// In en, this message translates to:
  /// **'{name} · no audio track'**
  String e4bCard(String name);

  /// No description provided for @getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get getHelp;

  /// No description provided for @noSoundHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Some screen recordings and muted clips are saved without an audio track. Record again with the microphone on, or pick a different video.'**
  String get noSoundHelpBody;

  /// No description provided for @e5Title.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save to Files'**
  String get e5Title;

  /// No description provided for @e5BodyFull.
  ///
  /// In en, this message translates to:
  /// **'Saving was interrupted because the destination is full.'**
  String get e5BodyFull;

  /// No description provided for @e5Body.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while saving to Files.'**
  String get e5Body;

  /// No description provided for @e5bTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your Tunely folder'**
  String get e5bTitle;

  /// No description provided for @e5bBody.
  ///
  /// In en, this message translates to:
  /// **'The folder you chose in Files was moved, renamed or deleted, so Tunely can\'t save there.'**
  String get e5bBody;

  /// No description provided for @e5Safe.
  ///
  /// In en, this message translates to:
  /// **'Your {format} is safe in Tunely'**
  String e5Safe(String format);

  /// No description provided for @e5SafeDetail.
  ///
  /// In en, this message translates to:
  /// **'Kept for {days} days · no need to convert again'**
  String e5SafeDetail(int days);

  /// No description provided for @saveOnIphoneInstead.
  ///
  /// In en, this message translates to:
  /// **'Save on this iPhone instead'**
  String get saveOnIphoneInstead;

  /// No description provided for @saveOnIphone.
  ///
  /// In en, this message translates to:
  /// **'Save on this iPhone'**
  String get saveOnIphone;

  /// No description provided for @shareInstead.
  ///
  /// In en, this message translates to:
  /// **'Share instead'**
  String get shareInstead;

  /// No description provided for @savedOnIphone.
  ///
  /// In en, this message translates to:
  /// **'Saved on this iPhone · Files › On My iPhone › Tunely'**
  String get savedOnIphone;

  /// No description provided for @stopBodyProgress.
  ///
  /// In en, this message translates to:
  /// **'You\'re {percent}% done. This won\'t use one of your free conversions.'**
  String stopBodyProgress(int percent);

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteTitle(String name);

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from My files on this iPhone. Copies you saved to your Tunely folder in Files are kept, and the original video in Photos is not touched.'**
  String get deleteBody;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete from Tunely'**
  String get deleteConfirm;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @filesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sounds yet'**
  String get filesEmptyTitle;

  /// No description provided for @filesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your MP3s, ringtones and converted files show up here, and a copy is saved to your Tunely folder in Files.'**
  String get filesEmptyBody;

  /// No description provided for @makeFirstSound.
  ///
  /// In en, this message translates to:
  /// **'Make your first sound'**
  String get makeFirstSound;

  /// No description provided for @moreFromMarberx.
  ///
  /// In en, this message translates to:
  /// **'More from Marberx · {pitch}'**
  String moreFromMarberx(String pitch);

  /// No description provided for @moreFromMarberxShort.
  ///
  /// In en, this message translates to:
  /// **'More from Marberx'**
  String get moreFromMarberxShort;

  /// No description provided for @get.
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get get;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions for {name}'**
  String moreActions(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @toastRingtoneAdded.
  ///
  /// In en, this message translates to:
  /// **'Ringtone added — find it in Sounds'**
  String get toastRingtoneAdded;

  /// No description provided for @toastCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get toastCopied;

  /// No description provided for @toastFreeLeft.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} free conversions left today'**
  String toastFreeLeft(int remaining, int total);

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @toastWelcomePro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tunely Pro!'**
  String get toastWelcomePro;

  /// No description provided for @toastIcloud.
  ///
  /// In en, this message translates to:
  /// **'File is still downloading from iCloud…'**
  String get toastIcloud;

  /// No description provided for @galleryToasts.
  ///
  /// In en, this message translates to:
  /// **'Toast catalogue'**
  String get galleryToasts;

  /// No description provided for @chooseAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get chooseAnotherFile;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @o1Title.
  ///
  /// In en, this message translates to:
  /// **'Any video,\nyour ringtone'**
  String get o1Title;

  /// No description provided for @o1Body.
  ///
  /// In en, this message translates to:
  /// **'Pull the sound out of any video, keep the best part and set it in seconds. MP3 and other formats too.'**
  String get o1Body;

  /// No description provided for @o1DemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Dance night'**
  String get o1DemoTitle;

  /// No description provided for @o1DemoMeta.
  ///
  /// In en, this message translates to:
  /// **'Ringtone · 0:30'**
  String get o1DemoMeta;

  /// No description provided for @o2Title.
  ///
  /// In en, this message translates to:
  /// **'What do you want to make?'**
  String get o2Title;

  /// No description provided for @o2Body.
  ///
  /// In en, this message translates to:
  /// **'We\'ll put your favourite tool first.'**
  String get o2Body;

  /// No description provided for @goalRingtones.
  ///
  /// In en, this message translates to:
  /// **'Ringtones'**
  String get goalRingtones;

  /// No description provided for @goalRingtonesDetail.
  ///
  /// In en, this message translates to:
  /// **'Ringtones, alarms and text tones'**
  String get goalRingtonesDetail;

  /// No description provided for @goalMp3.
  ///
  /// In en, this message translates to:
  /// **'MP3 from videos'**
  String get goalMp3;

  /// No description provided for @goalMp3Detail.
  ///
  /// In en, this message translates to:
  /// **'Keep just the sound of a video'**
  String get goalMp3Detail;

  /// No description provided for @goalConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert audio files'**
  String get goalConvert;

  /// No description provided for @goalConvertDetail.
  ///
  /// In en, this message translates to:
  /// **'MP3, M4A, WAV and more'**
  String get goalConvertDetail;

  /// No description provided for @o2Footer.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings.'**
  String get o2Footer;

  /// No description provided for @o3Title.
  ///
  /// In en, this message translates to:
  /// **'How often will you use Tunely?'**
  String get o3Title;

  /// No description provided for @o3Body.
  ///
  /// In en, this message translates to:
  /// **'So we only suggest what\'s worth it for you.'**
  String get o3Body;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get freqDaily;

  /// No description provided for @freqDailyDetail.
  ///
  /// In en, this message translates to:
  /// **'Music, clips and ringtones all the time'**
  String get freqDailyDetail;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'A few times a week'**
  String get freqWeekly;

  /// No description provided for @freqWeeklyDetail.
  ///
  /// In en, this message translates to:
  /// **'Whenever something catches my ear'**
  String get freqWeeklyDetail;

  /// No description provided for @freqRarely.
  ///
  /// In en, this message translates to:
  /// **'Just once in a while'**
  String get freqRarely;

  /// No description provided for @freqRarelyDetail.
  ///
  /// In en, this message translates to:
  /// **'A ringtone or a file now and then'**
  String get freqRarelyDetail;

  /// No description provided for @o4Title.
  ///
  /// In en, this message translates to:
  /// **'Honest and simple.\nNo surprises.'**
  String get o4Title;

  /// No description provided for @o4FreeTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} free conversions every day'**
  String o4FreeTitle(int count);

  /// No description provided for @o4FreeBody.
  ///
  /// In en, this message translates to:
  /// **'Full quality, no watermark. Your free uses come back every morning.'**
  String get o4FreeBody;

  /// No description provided for @o4AdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Short ads, never mid-task'**
  String get o4AdsTitle;

  /// No description provided for @o4AdsBody.
  ///
  /// In en, this message translates to:
  /// **'Ads only appear between tasks, after your file is saved. Pro removes them.'**
  String get o4AdsBody;

  /// No description provided for @o4TrialTitle.
  ///
  /// In en, this message translates to:
  /// **'A reminder before any trial ends'**
  String get o4TrialTitle;

  /// No description provided for @o4TrialBody.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications and we\'ll remind you a day before. Cancel in two taps.'**
  String get o4TrialBody;

  /// No description provided for @o4DeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Made on your iPhone'**
  String get o4DeviceTitle;

  /// No description provided for @o4DeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Your files are converted on the device and never uploaded.'**
  String get o4DeviceBody;

  /// No description provided for @soundsGood.
  ///
  /// In en, this message translates to:
  /// **'Sounds good'**
  String get soundsGood;

  /// No description provided for @o5Title.
  ///
  /// In en, this message translates to:
  /// **'Your library stays private'**
  String get o5Title;

  /// No description provided for @o5Body.
  ///
  /// In en, this message translates to:
  /// **'Tunely only sees the videos and songs you choose. No full photo-library access needed, and nothing is uploaded.'**
  String get o5Body;

  /// No description provided for @o5Pill.
  ///
  /// In en, this message translates to:
  /// **'Only the file you pick'**
  String get o5Pill;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @convertedOnIphone.
  ///
  /// In en, this message translates to:
  /// **'Converted on your iPhone'**
  String get convertedOnIphone;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStep(int step, int total);

  /// No description provided for @proCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Tunely Pro'**
  String get proCardTitle;

  /// No description provided for @proCardBody.
  ///
  /// In en, this message translates to:
  /// **'Unlimited, no ads, all formats'**
  String get proCardBody;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsWhatIMake.
  ///
  /// In en, this message translates to:
  /// **'What I make'**
  String get settingsWhatIMake;

  /// No description provided for @settingsDefaultFormat.
  ///
  /// In en, this message translates to:
  /// **'Default format'**
  String get settingsDefaultFormat;

  /// No description provided for @settingsSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to'**
  String get settingsSaveTo;

  /// No description provided for @settingsSaveToNone.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get settingsSaveToNone;

  /// No description provided for @settingsSaveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Files › {folder}'**
  String settingsSaveToFolder(String folder);

  /// No description provided for @settingsHelpMore.
  ///
  /// In en, this message translates to:
  /// **'Help & more'**
  String get settingsHelpMore;

  /// No description provided for @settingsHowRingtone.
  ///
  /// In en, this message translates to:
  /// **'How to set a ringtone'**
  String get settingsHowRingtone;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get settingsHelp;

  /// No description provided for @settingsRate.
  ///
  /// In en, this message translates to:
  /// **'Rate Tunely'**
  String get settingsRate;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get settingsManage;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicences.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get settingsLicences;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get settingsDebug;

  /// No description provided for @debugUnlockPro.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro (testing)'**
  String get debugUnlockPro;

  /// No description provided for @debugLockPro.
  ///
  /// In en, this message translates to:
  /// **'Lock Pro (testing)'**
  String get debugLockPro;

  /// No description provided for @editExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Exit?'**
  String get editExitTitle;

  /// No description provided for @editExitBody.
  ///
  /// In en, this message translates to:
  /// **'Current edits will not be saved. Are you sure you want to exit?'**
  String get editExitBody;

  /// No description provided for @editExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Exit'**
  String get editExitConfirm;

  /// No description provided for @editExitContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Editing'**
  String get editExitContinue;

  /// No description provided for @formatKbps.
  ///
  /// In en, this message translates to:
  /// **'{format} · {kbps} kbps'**
  String formatKbps(String format, int kbps);

  /// No description provided for @defaultFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Default format'**
  String get defaultFormatTitle;

  /// No description provided for @defaultFormatBody.
  ///
  /// In en, this message translates to:
  /// **'New conversions start with this format and quality. You can still change them each time.'**
  String get defaultFormatBody;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that link'**
  String get couldNotOpen;

  /// No description provided for @prefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get prefsTitle;

  /// No description provided for @prefsWhat.
  ///
  /// In en, this message translates to:
  /// **'What do you make most?'**
  String get prefsWhat;

  /// No description provided for @prefsGoalRingtones.
  ///
  /// In en, this message translates to:
  /// **'Ringtones, alarms and text tones'**
  String get prefsGoalRingtones;

  /// No description provided for @prefsGoalMp3.
  ///
  /// In en, this message translates to:
  /// **'MP3 from videos'**
  String get prefsGoalMp3;

  /// No description provided for @prefsGoalConvert.
  ///
  /// In en, this message translates to:
  /// **'Converting audio files'**
  String get prefsGoalConvert;

  /// No description provided for @prefsHowOften.
  ///
  /// In en, this message translates to:
  /// **'How often?'**
  String get prefsHowOften;

  /// No description provided for @prefsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get prefsDaily;

  /// No description provided for @prefsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get prefsWeekly;

  /// No description provided for @prefsRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get prefsRarely;

  /// No description provided for @prefsInfo.
  ///
  /// In en, this message translates to:
  /// **'Your choice decides which tool is first on Home and the default settings for new conversions.'**
  String get prefsInfo;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get filterAudio;

  /// No description provided for @filterRingtones.
  ///
  /// In en, this message translates to:
  /// **'Ringtones'**
  String get filterRingtones;

  /// No description provided for @filterAlarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get filterAlarms;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchFiles.
  ///
  /// In en, this message translates to:
  /// **'Search your files'**
  String get searchFiles;

  /// No description provided for @filesFooter.
  ///
  /// In en, this message translates to:
  /// **'Copies saved to your Tunely folder in Files, kept even if you delete the app'**
  String get filesFooter;

  /// No description provided for @filesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No files match'**
  String get filesNoMatch;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @metaWithDate.
  ///
  /// In en, this message translates to:
  /// **'{meta} · {date}'**
  String metaWithDate(String meta, String date);

  /// No description provided for @metaAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm · {duration}'**
  String metaAlarm(String duration);

  /// No description provided for @metaTextTone.
  ///
  /// In en, this message translates to:
  /// **'Text tone · {duration}'**
  String metaTextTone(String duration);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename file'**
  String get renameTitle;

  /// No description provided for @renameHint.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get renameHint;

  /// No description provided for @renameTaken.
  ///
  /// In en, this message translates to:
  /// **'A file with that name already exists'**
  String get renameTaken;

  /// No description provided for @setRingtoneAction.
  ///
  /// In en, this message translates to:
  /// **'Set as ringtone'**
  String get setRingtoneAction;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your ringtone'**
  String get guideTitle;

  /// No description provided for @guideStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 3 · about 20 seconds'**
  String guideStep(int step);

  /// No description provided for @guide1Title.
  ///
  /// In en, this message translates to:
  /// **'Tap “Use as Ringtone”'**
  String get guide1Title;

  /// No description provided for @guide1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap Open share menu below. Then scroll down and choose Use as Ringtone. That’s it — no GarageBand needed on iOS 26.'**
  String get guide1Body;

  /// No description provided for @guideShareSave.
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get guideShareSave;

  /// No description provided for @guideShareUse.
  ///
  /// In en, this message translates to:
  /// **'Use as Ringtone'**
  String get guideShareUse;

  /// No description provided for @guideShareAirdrop.
  ///
  /// In en, this message translates to:
  /// **'AirDrop'**
  String get guideShareAirdrop;

  /// No description provided for @guideReady.
  ///
  /// In en, this message translates to:
  /// **'{duration} · ready'**
  String guideReady(String duration);

  /// No description provided for @guideOpenShare.
  ///
  /// In en, this message translates to:
  /// **'Open share menu'**
  String get guideOpenShare;

  /// No description provided for @guide2Title.
  ///
  /// In en, this message translates to:
  /// **'Pick it in Settings'**
  String get guide2Title;

  /// No description provided for @guide2Body.
  ///
  /// In en, this message translates to:
  /// **'Your sound is now in Settings › Sounds & Haptics › Ringtone. Tick it, or give it to one contact.'**
  String get guide2Body;

  /// No description provided for @guide2Path.
  ///
  /// In en, this message translates to:
  /// **'Settings › Sounds & Haptics › Ringtone'**
  String get guide2Path;

  /// No description provided for @guide2Default.
  ///
  /// In en, this message translates to:
  /// **'Reflection (default)'**
  String get guide2Default;

  /// No description provided for @guide2Tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: set it for one person in Contacts › Edit › Ringtone.'**
  String get guide2Tip;

  /// No description provided for @guideOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get guideOpenSettings;

  /// No description provided for @guide3Title.
  ///
  /// In en, this message translates to:
  /// **'Done — it works!'**
  String get guide3Title;

  /// No description provided for @guide3Body.
  ///
  /// In en, this message translates to:
  /// **'Next time it takes two taps. Make alarms and text tones the same way.'**
  String get guide3Body;

  /// No description provided for @guide3Card.
  ///
  /// In en, this message translates to:
  /// **'All set! Ask a friend to call you to hear it.'**
  String get guide3Card;

  /// No description provided for @makeAnother.
  ///
  /// In en, this message translates to:
  /// **'Make another'**
  String get makeAnother;

  /// No description provided for @guideGarageBandLink.
  ///
  /// In en, this message translates to:
  /// **'On iOS 18 or older? Use the GarageBand way'**
  String get guideGarageBandLink;

  /// No description provided for @guideNoFileBody.
  ///
  /// In en, this message translates to:
  /// **'Make a ringtone first. After saving, Tunely walks you through these steps.'**
  String get guideNoFileBody;

  /// No description provided for @makeRingtone.
  ///
  /// In en, this message translates to:
  /// **'Make a ringtone'**
  String get makeRingtone;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @gbTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a ringtone with GarageBand'**
  String get gbTitle;

  /// No description provided for @gbIntro.
  ///
  /// In en, this message translates to:
  /// **'On iOS 18 and older, iPhone only accepts ringtones exported from GarageBand. It’s free from Apple and takes about a minute.'**
  String get gbIntro;

  /// No description provided for @gbStep1.
  ///
  /// In en, this message translates to:
  /// **'Save your ringtone to Files with Save to Files or Share › Save to Files.'**
  String get gbStep1;

  /// No description provided for @gbStep2.
  ///
  /// In en, this message translates to:
  /// **'Open GarageBand (free on the App Store) and start a new song with Audio Recorder.'**
  String get gbStep2;

  /// No description provided for @gbStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap the Tracks view, then the loop icon, then Files › Browse items from the Files app, and pick your ringtone.'**
  String get gbStep3;

  /// No description provided for @gbStep4.
  ///
  /// In en, this message translates to:
  /// **'Drag it onto the track and tap the arrow at the top left › My Songs.'**
  String get gbStep4;

  /// No description provided for @gbStep5.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold the song, tap Share › Ringtone, then Export.'**
  String get gbStep5;

  /// No description provided for @gbStep6.
  ///
  /// In en, this message translates to:
  /// **'Tap Use sound as… › Standard Ringtone. It now appears in Settings › Sounds & Haptics › Ringtone.'**
  String get gbStep6;

  /// No description provided for @gbStepNumber.
  ///
  /// In en, this message translates to:
  /// **'{number}'**
  String gbStepNumber(int number);

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpTitle;

  /// No description provided for @helpSearch.
  ///
  /// In en, this message translates to:
  /// **'Search help'**
  String get helpSearch;

  /// No description provided for @helpNoResults.
  ///
  /// In en, this message translates to:
  /// **'No answers match your search. Try another word or contact us.'**
  String get helpNoResults;

  /// No description provided for @mailSubject.
  ///
  /// In en, this message translates to:
  /// **'Tunely support'**
  String get mailSubject;

  /// No description provided for @mailBody.
  ///
  /// In en, this message translates to:
  /// **'App version: {version}\niOS: {os}\n\nTell us what happened:\n'**
  String mailBody(String version, String os);

  /// No description provided for @faqAdsQ.
  ///
  /// In en, this message translates to:
  /// **'Why do I see ads?'**
  String get faqAdsQ;

  /// No description provided for @faqAdsA.
  ///
  /// In en, this message translates to:
  /// **'Ads keep Tunely free. You only see a short ad between tasks, after your file is already saved, never while converting. Tunely Pro removes all ads.'**
  String get faqAdsA;

  /// No description provided for @faqSetRingtoneQ.
  ///
  /// In en, this message translates to:
  /// **'How do I set a ringtone?'**
  String get faqSetRingtoneQ;

  /// No description provided for @faqSetRingtoneA.
  ///
  /// In en, this message translates to:
  /// **'After you make a ringtone, tap Set as ringtone and follow the 3 steps.\n• On iOS 26: tap Share, then Use as Ringtone. Then pick it in iPhone Settings › Sounds & Haptics › Ringtone (it’s at the top).\n• On iOS 18 or older: we guide you through the free GarageBand app (Help › “Set a ringtone with GarageBand”).'**
  String get faqSetRingtoneA;

  /// No description provided for @faqDrmQ.
  ///
  /// In en, this message translates to:
  /// **'Why can’t I convert Apple Music songs?'**
  String get faqDrmQ;

  /// No description provided for @faqDrmA.
  ///
  /// In en, this message translates to:
  /// **'Songs from Apple Music and other streaming services are copy-protected (DRM), so no app can convert them. Your own videos, voice memos and DRM-free music files work fine.'**
  String get faqDrmA;

  /// No description provided for @faqQualityQ.
  ///
  /// In en, this message translates to:
  /// **'Will quality drop?'**
  String get faqQualityQ;

  /// No description provided for @faqQualityA.
  ///
  /// In en, this message translates to:
  /// **'Choose High (256 kbps) or Best (320 kbps) and most people can’t hear a difference. Before you convert, Tunely shows the estimated file size. If your file is already lower quality, a higher setting won’t make it better.'**
  String get faqQualityA;

  /// No description provided for @faqWhereSavedQ.
  ///
  /// In en, this message translates to:
  /// **'Where are my files saved?'**
  String get faqWhereSavedQ;

  /// No description provided for @faqWhereSavedA.
  ///
  /// In en, this message translates to:
  /// **'Every file you make appears in My files inside Tunely. When you tap Save to Files, Tunely also saves a copy to your Tunely folder in Files (iCloud Drive › Tunely by default; you choose it the first time). Copies in that folder stay even if you delete the app. Files only inside Tunely are removed if you delete the app.'**
  String get faqWhereSavedA;

  /// No description provided for @faqFreeConversionsQ.
  ///
  /// In en, this message translates to:
  /// **'How do free conversions work?'**
  String get faqFreeConversionsQ;

  /// No description provided for @faqFreeConversionsA.
  ///
  /// In en, this message translates to:
  /// **'You get 3 full-quality conversions every day, ringtones included. They reset at midnight. Failed or cancelled conversions never count. When you run out, you can watch a short ad for 1 more (up to 2 a day), wait until tomorrow, or go Pro for unlimited.'**
  String get faqFreeConversionsA;

  /// No description provided for @faqCancelQ.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my subscription?'**
  String get faqCancelQ;

  /// No description provided for @faqCancelA.
  ///
  /// In en, this message translates to:
  /// **'Open Tunely Settings › Manage subscription, or iPhone Settings › [your name] › Subscriptions › Tunely Pro. If you allow notifications, we remind you a day before any free trial ends. Cancel at least 24 hours before the renewal date to avoid the next charge.'**
  String get faqCancelA;

  /// No description provided for @faqWhatCanIConvertQ.
  ///
  /// In en, this message translates to:
  /// **'What can I convert?'**
  String get faqWhatCanIConvertQ;

  /// No description provided for @faqWhatCanIConvertA.
  ///
  /// In en, this message translates to:
  /// **'Videos from Photos or Files (MOV, MP4, M4V) and audio files (MP3, M4A, AAC, WAV, AIFF, CAF, FLAC). You can save as MP3, M4A or WAV for free, and as FLAC, AAC or OGG with Pro.'**
  String get faqWhatCanIConvertA;

  /// No description provided for @faqVideoToMp3Q.
  ///
  /// In en, this message translates to:
  /// **'How do I turn a video into an MP3?'**
  String get faqVideoToMp3Q;

  /// No description provided for @faqVideoToMp3A.
  ///
  /// In en, this message translates to:
  /// **'On Home, tap Video to MP3 (or the big button), pick a video, check the format and quality, then tap Convert to MP3. When it’s done, tap Save to Files or Share.'**
  String get faqVideoToMp3A;

  /// No description provided for @faqPrivacyQ.
  ///
  /// In en, this message translates to:
  /// **'Does Tunely upload my files?'**
  String get faqPrivacyQ;

  /// No description provided for @faqPrivacyA.
  ///
  /// In en, this message translates to:
  /// **'No. Everything is converted on your iPhone. Your videos and songs are never uploaded, and ads never see your files.'**
  String get faqPrivacyA;

  /// No description provided for @faqOfflineQ.
  ///
  /// In en, this message translates to:
  /// **'Do I need internet?'**
  String get faqOfflineQ;

  /// No description provided for @faqOfflineA.
  ///
  /// In en, this message translates to:
  /// **'Converting works without internet. You need internet to buy or restore Pro, to download videos stored only in iCloud, and to load ads.'**
  String get faqOfflineA;

  /// No description provided for @faqNoAudioQ.
  ///
  /// In en, this message translates to:
  /// **'Why does it say the video has no sound?'**
  String get faqNoAudioQ;

  /// No description provided for @faqNoAudioA.
  ///
  /// In en, this message translates to:
  /// **'That video has no audio track (some screen recordings and muted clips), so there’s nothing to convert. Try another video.'**
  String get faqNoAudioA;

  /// No description provided for @faqIcloudQ.
  ///
  /// In en, this message translates to:
  /// **'It says “still in iCloud”. What do I do?'**
  String get faqIcloudQ;

  /// No description provided for @faqIcloudA.
  ///
  /// In en, this message translates to:
  /// **'The video isn’t fully on your iPhone yet. Connect to Wi-Fi (or turn off Low Data Mode) and tap Try again, or open it once in Photos so it downloads.'**
  String get faqIcloudA;

  /// No description provided for @faqConversionFailedQ.
  ///
  /// In en, this message translates to:
  /// **'Converting failed. What now?'**
  String get faqConversionFailedQ;

  /// No description provided for @faqConversionFailedA.
  ///
  /// In en, this message translates to:
  /// **'Tap Try compatibility mode. It works for almost every video. Your original file is never changed. If it still fails, tap Contact support; the error code is added for us automatically.'**
  String get faqConversionFailedA;

  /// No description provided for @faqStorageQ.
  ///
  /// In en, this message translates to:
  /// **'It says I need more space.'**
  String get faqStorageQ;

  /// No description provided for @faqStorageA.
  ///
  /// In en, this message translates to:
  /// **'Converting needs a little room for a temporary copy. Empty Recently Deleted in Photos, remove old files in My files, or choose Standard quality, then tap Check again.'**
  String get faqStorageA;

  /// No description provided for @faqBackgroundQ.
  ///
  /// In en, this message translates to:
  /// **'Can I keep converting when I leave the app?'**
  String get faqBackgroundQ;

  /// No description provided for @faqBackgroundA.
  ///
  /// In en, this message translates to:
  /// **'On iOS 26, yes: it keeps going in the background. On older iOS, it may pause until you come back, and then it continues. A paused job never uses a free conversion.'**
  String get faqBackgroundA;

  /// No description provided for @faqRingtoneLengthQ.
  ///
  /// In en, this message translates to:
  /// **'How long can a ringtone be?'**
  String get faqRingtoneLengthQ;

  /// No description provided for @faqRingtoneLengthA.
  ///
  /// In en, this message translates to:
  /// **'Up to 30 seconds. Drag the handles to pick the part you like; fade in and out are added for you (you can change them).'**
  String get faqRingtoneLengthA;

  /// No description provided for @faqAlarmTextTonesQ.
  ///
  /// In en, this message translates to:
  /// **'What are alarm and text tones?'**
  String get faqAlarmTextTonesQ;

  /// No description provided for @faqAlarmTextTonesA.
  ///
  /// In en, this message translates to:
  /// **'They’re short sounds for alarms and messages. Making them is part of Tunely Pro. Ringtones are free.'**
  String get faqAlarmTextTonesA;

  /// No description provided for @faqRingtoneMissingQ.
  ///
  /// In en, this message translates to:
  /// **'I can’t find my ringtone in Settings.'**
  String get faqRingtoneMissingQ;

  /// No description provided for @faqRingtoneMissingA.
  ///
  /// In en, this message translates to:
  /// **'Make sure you finished the last step of the guide. On iOS 26 it appears at the top of Settings › Sounds & Haptics › Ringtone. On older iOS, check that you exported it from GarageBand as a ringtone.'**
  String get faqRingtoneMissingA;

  /// No description provided for @faqTrimFadeQ.
  ///
  /// In en, this message translates to:
  /// **'How do I cut or fade a song?'**
  String get faqTrimFadeQ;

  /// No description provided for @faqTrimFadeA.
  ///
  /// In en, this message translates to:
  /// **'On the Convert screen, tap Trim & fade. Drag the handles or use −1 s / +1 s, set fade in and out, then tap Done.'**
  String get faqTrimFadeA;

  /// No description provided for @faqMergeQ.
  ///
  /// In en, this message translates to:
  /// **'How do I join songs into one?'**
  String get faqMergeQ;

  /// No description provided for @faqMergeA.
  ///
  /// In en, this message translates to:
  /// **'Tap Merge audio on Home (Pro), pick 2 to 10 files, drag to change the order, choose a crossfade, then tap Merge. Your original files are not changed.'**
  String get faqMergeA;

  /// No description provided for @faqBatchQ.
  ///
  /// In en, this message translates to:
  /// **'Can I convert many files at once?'**
  String get faqBatchQ;

  /// No description provided for @faqBatchA.
  ///
  /// In en, this message translates to:
  /// **'Yes, with Pro: pick up to 50 files and tap Continue. Finished files are saved as they complete; if one fails, you can retry just that one.'**
  String get faqBatchA;

  /// No description provided for @faqVolumeBoostQ.
  ///
  /// In en, this message translates to:
  /// **'What is volume boost?'**
  String get faqVolumeBoostQ;

  /// No description provided for @faqVolumeBoostA.
  ///
  /// In en, this message translates to:
  /// **'Pro can make quiet audio up to +6 dB louder without distortion.'**
  String get faqVolumeBoostA;

  /// No description provided for @faqProQ.
  ///
  /// In en, this message translates to:
  /// **'What do I get with Tunely Pro?'**
  String get faqProQ;

  /// No description provided for @faqProA.
  ///
  /// In en, this message translates to:
  /// **'Unlimited conversions and ringtones, no ads, FLAC/AAC/OGG formats, batch (up to 50 files), merge audio, volume boost, and alarm and text tones.'**
  String get faqProA;

  /// No description provided for @faqTrialQ.
  ///
  /// In en, this message translates to:
  /// **'How does the free trial work?'**
  String get faqTrialQ;

  /// No description provided for @faqTrialA.
  ///
  /// In en, this message translates to:
  /// **'If you’re eligible, Yearly starts with 3 days free. You won’t be charged until the trial ends, and you can cancel anytime before. If you’ve had a trial before, the app shows the regular price instead.'**
  String get faqTrialA;

  /// No description provided for @faqRestoreQ.
  ///
  /// In en, this message translates to:
  /// **'I bought Pro but it’s not showing.'**
  String get faqRestoreQ;

  /// No description provided for @faqRestoreA.
  ///
  /// In en, this message translates to:
  /// **'Tap Settings › Restore purchases. Make sure you’re signed in with the same Apple Account you used to buy. If it says “No purchases found”, check the account in iPhone Settings and try again.'**
  String get faqRestoreA;

  /// No description provided for @faqRefundQ.
  ///
  /// In en, this message translates to:
  /// **'Can I get a refund?'**
  String get faqRefundQ;

  /// No description provided for @faqRefundA.
  ///
  /// In en, this message translates to:
  /// **'Refunds are handled by Apple. Go to reportaproblem.apple.com and choose Tunely Pro.'**
  String get faqRefundA;

  /// No description provided for @faqDevicesQ.
  ///
  /// In en, this message translates to:
  /// **'Does Pro work on my other devices?'**
  String get faqDevicesQ;

  /// No description provided for @faqDevicesA.
  ///
  /// In en, this message translates to:
  /// **'Yes, on any iPhone signed in with the same Apple Account. Tap Restore purchases on the new device.'**
  String get faqDevicesA;

  /// No description provided for @faqDeleteQ.
  ///
  /// In en, this message translates to:
  /// **'Does deleting a file in Tunely delete my original?'**
  String get faqDeleteQ;

  /// No description provided for @faqDeleteA.
  ///
  /// In en, this message translates to:
  /// **'No. Deleting removes the file from My files only. The original video in Photos and any copies you saved to your Tunely folder in Files are kept.'**
  String get faqDeleteA;

  /// No description provided for @faqRenameQ.
  ///
  /// In en, this message translates to:
  /// **'Can I rename files?'**
  String get faqRenameQ;

  /// No description provided for @faqRenameA.
  ///
  /// In en, this message translates to:
  /// **'Yes. In My files, tap ⋯ next to a file, then Rename.'**
  String get faqRenameA;

  /// No description provided for @faqFolderMissingQ.
  ///
  /// In en, this message translates to:
  /// **'My Tunely folder can’t be found.'**
  String get faqFolderMissingQ;

  /// No description provided for @faqFolderMissingA.
  ///
  /// In en, this message translates to:
  /// **'The folder was moved, renamed or deleted. Tap Choose folder again and pick a folder (iCloud Drive › Tunely is a good choice).'**
  String get faqFolderMissingA;

  /// No description provided for @faqAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Do I need an account?'**
  String get faqAccountQ;

  /// No description provided for @faqAccountA.
  ///
  /// In en, this message translates to:
  /// **'No. Everything works without one. An account is only for invite rewards.'**
  String get faqAccountA;

  /// No description provided for @faqInvitesQ.
  ///
  /// In en, this message translates to:
  /// **'How do invite rewards work?'**
  String get faqInvitesQ;

  /// No description provided for @faqInvitesA.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings › Invite friends, create a free account and share your link. Your friend gets a week of Pro right away (no account needed). You get a week when they make their first file.'**
  String get faqInvitesA;

  /// No description provided for @faqInviteCodeQ.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code. Where do I enter it?'**
  String get faqInviteCodeQ;

  /// No description provided for @faqInviteCodeA.
  ///
  /// In en, this message translates to:
  /// **'Settings › Have an invite code? If you opened your friend’s link, the code is filled in for you.'**
  String get faqInviteCodeA;

  /// No description provided for @faqDeleteAccountQ.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account?'**
  String get faqDeleteAccountQ;

  /// No description provided for @faqDeleteAccountA.
  ///
  /// In en, this message translates to:
  /// **'Settings › Account › Delete account. Your files and your Pro subscription are not affected.'**
  String get faqDeleteAccountA;

  /// No description provided for @faqTrackingQ.
  ///
  /// In en, this message translates to:
  /// **'Why does iPhone ask about tracking?'**
  String get faqTrackingQ;

  /// No description provided for @faqTrackingA.
  ///
  /// In en, this message translates to:
  /// **'Ad networks can show more relevant ads if you allow it. Either answer is fine, and Tunely works the same. You can change it anytime in iPhone Settings › Privacy & Security › Tracking.'**
  String get faqTrackingA;

  /// No description provided for @faqRemoveAdsQ.
  ///
  /// In en, this message translates to:
  /// **'How do I remove ads?'**
  String get faqRemoveAdsQ;

  /// No description provided for @faqRemoveAdsA.
  ///
  /// In en, this message translates to:
  /// **'Get Tunely Pro. All ads disappear right away.'**
  String get faqRemoveAdsA;

  /// No description provided for @faqMoreAppsQ.
  ///
  /// In en, this message translates to:
  /// **'What are the app suggestions from Marberx?'**
  String get faqMoreAppsQ;

  /// No description provided for @faqMoreAppsA.
  ///
  /// In en, this message translates to:
  /// **'Marberx makes Tunely and a few other small apps (like Shrink: Video Compressor). We sometimes show one that fits what you’re doing. You can hide a suggestion with ×, and nobody is paid when you install.'**
  String get faqMoreAppsA;

  /// No description provided for @o1DemoFile.
  ///
  /// In en, this message translates to:
  /// **'Dance_night.mov'**
  String get o1DemoFile;

  /// No description provided for @pwBadge.
  ///
  /// In en, this message translates to:
  /// **'Tunely Pro'**
  String get pwBadge;

  /// No description provided for @pwHeaderRingtones.
  ///
  /// In en, this message translates to:
  /// **'Unlimited ringtones, alarms & text tones'**
  String get pwHeaderRingtones;

  /// No description provided for @pwHeaderMp3.
  ///
  /// In en, this message translates to:
  /// **'Unlimited MP3s from all your videos'**
  String get pwHeaderMp3;

  /// No description provided for @pwHeaderConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert every file, every format'**
  String get pwHeaderConvert;

  /// No description provided for @pwBenefitRingtones.
  ///
  /// In en, this message translates to:
  /// **'Unlimited ringtones'**
  String get pwBenefitRingtones;

  /// No description provided for @pwBenefitConversions.
  ///
  /// In en, this message translates to:
  /// **'Unlimited conversions'**
  String get pwBenefitConversions;

  /// No description provided for @pwBenefitFormats.
  ///
  /// In en, this message translates to:
  /// **'FLAC, AAC, OGG formats'**
  String get pwBenefitFormats;

  /// No description provided for @pwBenefitBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch 50 files at once'**
  String get pwBenefitBatch;

  /// No description provided for @pwBenefitNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads, merge & boost'**
  String get pwBenefitNoAds;

  /// No description provided for @pwToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get pwToday;

  /// No description provided for @pwTodayDetail.
  ///
  /// In en, this message translates to:
  /// **'Full access, free'**
  String get pwTodayDetail;

  /// No description provided for @pwDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String pwDay(int day);

  /// No description provided for @pwReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get pwReminder;

  /// No description provided for @pwStarts.
  ///
  /// In en, this message translates to:
  /// **'{price}/yr starts'**
  String pwStarts(String price);

  /// No description provided for @pwYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get pwYearly;

  /// No description provided for @pwWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get pwWeekly;

  /// No description provided for @pwLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get pwLifetime;

  /// No description provided for @pwYearlyTrial.
  ///
  /// In en, this message translates to:
  /// **'{days} days free, then {price} / year'**
  String pwYearlyTrial(int days, String price);

  /// No description provided for @pwYearlyNoTrial.
  ///
  /// In en, this message translates to:
  /// **'Billed every year'**
  String get pwYearlyNoTrial;

  /// No description provided for @pwWeeklyDetail.
  ///
  /// In en, this message translates to:
  /// **'Billed every week'**
  String get pwWeeklyDetail;

  /// No description provided for @pwLifetimeDetail.
  ///
  /// In en, this message translates to:
  /// **'Pay once, yours forever'**
  String get pwLifetimeDetail;

  /// No description provided for @pwPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{price} / wk'**
  String pwPerWeek(String price);

  /// No description provided for @pwSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE {percent}%'**
  String pwSave(int percent);

  /// No description provided for @pwTermsTrial.
  ///
  /// In en, this message translates to:
  /// **'Free for {days} days, then {price} / year. Cancel anytime.'**
  String pwTermsTrial(int days, String price);

  /// No description provided for @pwTermsYearly.
  ///
  /// In en, this message translates to:
  /// **'{price} / year. Cancel anytime.'**
  String pwTermsYearly(String price);

  /// No description provided for @pwTermsWeekly.
  ///
  /// In en, this message translates to:
  /// **'{price} / week. Cancel anytime.'**
  String pwTermsWeekly(String price);

  /// No description provided for @pwTermsLifetime.
  ///
  /// In en, this message translates to:
  /// **'{price} one-time purchase. No subscription.'**
  String pwTermsLifetime(String price);

  /// No description provided for @pwCtaTrial.
  ///
  /// In en, this message translates to:
  /// **'Start my free trial'**
  String get pwCtaTrial;

  /// No description provided for @pwCtaContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pwCtaContinue;

  /// No description provided for @pwCtaLifetime.
  ///
  /// In en, this message translates to:
  /// **'Buy lifetime'**
  String get pwCtaLifetime;

  /// No description provided for @pwRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get pwRestore;

  /// No description provided for @pwLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading prices from the App Store'**
  String get pwLoading;

  /// No description provided for @pwUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prices couldn\'t load. Check your connection and try again.'**
  String get pwUnavailable;

  /// No description provided for @p2FormatTitle.
  ///
  /// In en, this message translates to:
  /// **'{feature} is a Pro format'**
  String p2FormatTitle(String feature);

  /// No description provided for @p2FeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'{feature} is part of Tunely Pro'**
  String p2FeatureTitle(String feature);

  /// No description provided for @p2DetailFlac.
  ///
  /// In en, this message translates to:
  /// **'Lossless, studio-quality audio'**
  String get p2DetailFlac;

  /// No description provided for @p2DetailAac.
  ///
  /// In en, this message translates to:
  /// **'Small files with great quality'**
  String get p2DetailAac;

  /// No description provided for @p2DetailOgg.
  ///
  /// In en, this message translates to:
  /// **'Open format for Android, games and the web'**
  String get p2DetailOgg;

  /// No description provided for @p2DetailTones.
  ///
  /// In en, this message translates to:
  /// **'Custom sounds for alarms and messages'**
  String get p2DetailTones;

  /// No description provided for @p2DetailBoost.
  ///
  /// In en, this message translates to:
  /// **'Make quiet audio up to +6 dB louder'**
  String get p2DetailBoost;

  /// No description provided for @p2DetailMerge.
  ///
  /// In en, this message translates to:
  /// **'Join 2 to 10 files into one'**
  String get p2DetailMerge;

  /// No description provided for @p2DetailBatch.
  ///
  /// In en, this message translates to:
  /// **'Convert up to 50 files at once'**
  String get p2DetailBatch;

  /// No description provided for @p2DetailPro.
  ///
  /// In en, this message translates to:
  /// **'Everything in Tunely, unlimited'**
  String get p2DetailPro;

  /// No description provided for @p2Benefit1.
  ///
  /// In en, this message translates to:
  /// **'FLAC, AAC and OGG formats'**
  String get p2Benefit1;

  /// No description provided for @p2Benefit2.
  ///
  /// In en, this message translates to:
  /// **'Unlimited conversions, no ads'**
  String get p2Benefit2;

  /// No description provided for @p2Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Batch up to 50 files at once'**
  String get p2Benefit3;

  /// No description provided for @p2CtaTrial.
  ///
  /// In en, this message translates to:
  /// **'Try Pro free for {days} days'**
  String p2CtaTrial(int days);

  /// No description provided for @p2CtaNoTrial.
  ///
  /// In en, this message translates to:
  /// **'Get Tunely Pro'**
  String get p2CtaNoTrial;

  /// No description provided for @useMp3Free.
  ///
  /// In en, this message translates to:
  /// **'Use MP3 instead (free)'**
  String get useMp3Free;

  /// No description provided for @p3Used.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} free conversions used today'**
  String p3Used(int used, int total);

  /// No description provided for @p3Title.
  ///
  /// In en, this message translates to:
  /// **'You\'re on a roll. Keep going with Pro.'**
  String get p3Title;

  /// No description provided for @p3Body.
  ///
  /// In en, this message translates to:
  /// **'Unlimited conversions and ringtones, or come back when your free uses reset.'**
  String get p3Body;

  /// No description provided for @p3ResetsIn.
  ///
  /// In en, this message translates to:
  /// **'Free uses reset in'**
  String get p3ResetsIn;

  /// No description provided for @p3Cta.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited'**
  String get p3Cta;

  /// No description provided for @p3WatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad for 1 more'**
  String get p3WatchAd;

  /// No description provided for @p3Tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow'**
  String get p3Tomorrow;

  /// No description provided for @p4Title.
  ///
  /// In en, this message translates to:
  /// **'{count} files today — you\'re a natural'**
  String p4Title(int count);

  /// No description provided for @p4TrialDetail.
  ///
  /// In en, this message translates to:
  /// **'Go unlimited · {days} days free'**
  String p4TrialDetail(int days);

  /// No description provided for @p4NoTrialDetail.
  ///
  /// In en, this message translates to:
  /// **'Go unlimited'**
  String get p4NoTrialDetail;

  /// No description provided for @p4Cta.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get p4Cta;

  /// No description provided for @p5Title.
  ///
  /// In en, this message translates to:
  /// **'{count} files made with Tunely'**
  String p5Title(int count);

  /// No description provided for @p5StatMp3.
  ///
  /// In en, this message translates to:
  /// **'MP3s'**
  String get p5StatMp3;

  /// No description provided for @p5StatTones.
  ///
  /// In en, this message translates to:
  /// **'Ringtones'**
  String get p5StatTones;

  /// No description provided for @p5StatOther.
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get p5StatOther;

  /// No description provided for @p5Body.
  ///
  /// In en, this message translates to:
  /// **'You clearly love making sounds. Yearly Pro costs less than a coffee a month.'**
  String get p5Body;

  /// No description provided for @p5PlanTrial.
  ///
  /// In en, this message translates to:
  /// **'{price} / year · {days} days free'**
  String p5PlanTrial(String price, int days);

  /// No description provided for @p5PlanNoTrial.
  ///
  /// In en, this message translates to:
  /// **'{price} / year'**
  String p5PlanNoTrial(String price);

  /// No description provided for @p5PerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} / mo'**
  String p5PerMonth(String price);

  /// No description provided for @p5CtaTrial.
  ///
  /// In en, this message translates to:
  /// **'Start free trial'**
  String get p5CtaTrial;

  /// No description provided for @p5CtaNoTrial.
  ///
  /// In en, this message translates to:
  /// **'Get Yearly'**
  String get p5CtaNoTrial;

  /// No description provided for @p6Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'One-time offer, just for today'**
  String get p6Eyebrow;

  /// No description provided for @p6Off.
  ///
  /// In en, this message translates to:
  /// **'{percent}% OFF'**
  String p6Off(int percent);

  /// No description provided for @p6Sub.
  ///
  /// In en, this message translates to:
  /// **'your first year of Tunely Pro'**
  String get p6Sub;

  /// No description provided for @p6Price.
  ///
  /// In en, this message translates to:
  /// **'{price} / year'**
  String p6Price(String price);

  /// No description provided for @p6EndsIn.
  ///
  /// In en, this message translates to:
  /// **'Offer ends in'**
  String get p6EndsIn;

  /// No description provided for @p6Cta.
  ///
  /// In en, this message translates to:
  /// **'Claim {percent}% off'**
  String p6Cta(int percent);

  /// No description provided for @p6Terms.
  ///
  /// In en, this message translates to:
  /// **'{intro} for the first year, then {price} / year. Cancel anytime.'**
  String p6Terms(String intro, String price);

  /// No description provided for @p6NoThanks.
  ///
  /// In en, this message translates to:
  /// **'No thanks, continue with Free'**
  String get p6NoThanks;

  /// No description provided for @p7Title.
  ///
  /// In en, this message translates to:
  /// **'Your free trial ends tomorrow'**
  String get p7Title;

  /// No description provided for @p7Body.
  ///
  /// In en, this message translates to:
  /// **'As promised, here\'s your reminder. Keep Pro, or cancel before {date} and you won\'t be charged.'**
  String p7Body(String date);

  /// No description provided for @p7Started.
  ///
  /// In en, this message translates to:
  /// **'{date} · Trial started'**
  String p7Started(String date);

  /// No description provided for @p7StartedDetail.
  ///
  /// In en, this message translates to:
  /// **'You made {count} files with Pro'**
  String p7StartedDetail(int count);

  /// No description provided for @p7Today.
  ///
  /// In en, this message translates to:
  /// **'Today · Reminder'**
  String get p7Today;

  /// No description provided for @p7TodayDetail.
  ///
  /// In en, this message translates to:
  /// **'That\'s this message'**
  String get p7TodayDetail;

  /// No description provided for @p7Charge.
  ///
  /// In en, this message translates to:
  /// **'{date} · {price} / year starts'**
  String p7Charge(String date, String price);

  /// No description provided for @p7ChargeDetail.
  ///
  /// In en, this message translates to:
  /// **'Renews yearly until you cancel'**
  String get p7ChargeDetail;

  /// No description provided for @p7Keep.
  ///
  /// In en, this message translates to:
  /// **'Keep Pro'**
  String get p7Keep;

  /// No description provided for @p7Manage.
  ///
  /// In en, this message translates to:
  /// **'Manage or cancel subscription'**
  String get p7Manage;

  /// No description provided for @p7NotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your free trial ends tomorrow'**
  String get p7NotificationTitle;

  /// No description provided for @p7NotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Keep Pro or cancel in two taps.'**
  String get p7NotificationBody;

  /// No description provided for @p8Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get p8Eyebrow;

  /// No description provided for @p8Title.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off Pro\nfor returning friends'**
  String p8Title(int percent);

  /// No description provided for @p8Sub.
  ///
  /// In en, this message translates to:
  /// **'Your ringtones and files are still here.'**
  String get p8Sub;

  /// No description provided for @p8LastTone.
  ///
  /// In en, this message translates to:
  /// **'Your last ringtone · {when}'**
  String p8LastTone(String when);

  /// No description provided for @p8LastFile.
  ///
  /// In en, this message translates to:
  /// **'Your last file · {when}'**
  String p8LastFile(String when);

  /// No description provided for @p8Plan.
  ///
  /// In en, this message translates to:
  /// **'Yearly Pro'**
  String get p8Plan;

  /// No description provided for @p8PlanDetail.
  ///
  /// In en, this message translates to:
  /// **'First year, then {price} / year'**
  String p8PlanDetail(String price);

  /// No description provided for @p8Cta.
  ///
  /// In en, this message translates to:
  /// **'Get {percent}% off'**
  String p8Cta(int percent);

  /// No description provided for @p8Continue.
  ///
  /// In en, this message translates to:
  /// **'Continue with Free'**
  String get p8Continue;

  /// No description provided for @p9FailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase didn\'t go through'**
  String get p9FailedTitle;

  /// No description provided for @p9FailedBody.
  ///
  /// In en, this message translates to:
  /// **'The App Store declined the payment. You haven\'t been charged.'**
  String get p9FailedBody;

  /// No description provided for @p9FailedTip.
  ///
  /// In en, this message translates to:
  /// **'Check your payment method in Settings › Apple Account › Payment.'**
  String get p9FailedTip;

  /// No description provided for @p9RestoredTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to Pro'**
  String get p9RestoredTitle;

  /// No description provided for @p9RestoredBody.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is restored on this iPhone.'**
  String get p9RestoredBody;

  /// No description provided for @p9RestoredRenews.
  ///
  /// In en, this message translates to:
  /// **'{plan} · renews {date}'**
  String p9RestoredRenews(String plan, String date);

  /// No description provided for @p9RestoredLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime · yours forever'**
  String get p9RestoredLifetime;

  /// No description provided for @p9PendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get p9PendingTitle;

  /// No description provided for @p9PendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your purchase needs approval (for example Ask to Buy). Pro unlocks as soon as it\'s approved.'**
  String get p9PendingBody;

  /// No description provided for @p9NoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No purchases found'**
  String get p9NoneTitle;

  /// No description provided for @p9NoneBody.
  ///
  /// In en, this message translates to:
  /// **'No Tunely Pro purchases were found for this Apple Account. Check you are signed in with the account you used to buy.'**
  String get p9NoneBody;

  /// No description provided for @p9OfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get p9OfflineTitle;

  /// No description provided for @p9OfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to buy or restore Pro. Converting still works without internet.'**
  String get p9OfflineBody;

  /// No description provided for @welcomePro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tunely Pro!'**
  String get welcomePro;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestore;

  /// No description provided for @relativeWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String relativeWeeks(int count);

  /// No description provided for @relativeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String relativeDays(int count);

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch convert'**
  String get batchTitle;

  /// No description provided for @batchSummary.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done · {format}'**
  String batchSummary(int done, int total, String format);

  /// No description provided for @batchFormatBitrate.
  ///
  /// In en, this message translates to:
  /// **'{format} {kbps} kbps'**
  String batchFormatBitrate(String format, int kbps);

  /// No description provided for @batchSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'about {seconds} s left'**
  String batchSecondsLeft(int seconds);

  /// No description provided for @batchMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min left'**
  String batchMinutesLeft(int minutes);

  /// No description provided for @batchWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get batchWaiting;

  /// No description provided for @batchConverting.
  ///
  /// In en, this message translates to:
  /// **'Converting…'**
  String get batchConverting;

  /// No description provided for @batchCaptionContinued.
  ///
  /// In en, this message translates to:
  /// **'On iOS 26 the batch keeps going in the background.'**
  String get batchCaptionContinued;

  /// No description provided for @batchCaptionLegacy.
  ///
  /// In en, this message translates to:
  /// **'On older iOS it may pause until you come back.'**
  String get batchCaptionLegacy;

  /// No description provided for @batchPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused while Tunely was in the background. It continues now.'**
  String get batchPaused;

  /// No description provided for @batchStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get batchStop;

  /// No description provided for @batchStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the batch?'**
  String get batchStopTitle;

  /// No description provided for @batchStopBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is finished yet.} =1{1 finished file is already saved.} other{{count} finished files are already saved.}} The rest won\'t be converted.'**
  String batchStopBody(int count);

  /// No description provided for @batchKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get batchKeepGoing;

  /// No description provided for @batchSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Converting {count} files'**
  String batchSystemTitle(int count);

  /// No description provided for @batchSystemProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String batchSystemProgress(int done, int total);

  /// No description provided for @batchNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Tunely'**
  String get batchNotificationTitle;

  /// No description provided for @batchNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file converted — tap to listen} other{{count} files converted — tap to listen}}'**
  String batchNotificationBody(int count);

  /// No description provided for @batchFinishedToast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file converted} other{{count} files converted}}'**
  String batchFinishedToast(int count);

  /// No description provided for @batchView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get batchView;

  /// No description provided for @batchFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch finished'**
  String get batchFinishedTitle;

  /// No description provided for @batchDoneChip.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String batchDoneChip(int count);

  /// No description provided for @batchFailedChip.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String batchFailedChip(int count);

  /// No description provided for @batchPartialBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Finished files are already saved. Only the failed one needs another try.} other{Finished files are already saved. Only the failed ones need another try.}}'**
  String batchPartialBody(int count);

  /// No description provided for @batchAllDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Every file is saved in My files.'**
  String get batchAllDoneBody;

  /// No description provided for @batchStoppedBody.
  ///
  /// In en, this message translates to:
  /// **'Stopped. Finished files are already saved in My files.'**
  String get batchStoppedBody;

  /// No description provided for @batchNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get batchNeedsAttention;

  /// No description provided for @batchCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get batchCompleted;

  /// No description provided for @batchMoreFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} more files'**
  String batchMoreFiles(int count);

  /// No description provided for @batchRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed ({count})'**
  String batchRetryFailed(int count);

  /// No description provided for @batchOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'Open My files'**
  String get batchOpenFiles;

  /// No description provided for @failNoAudio.
  ///
  /// In en, this message translates to:
  /// **'No audio track'**
  String get failNoAudio;

  /// No description provided for @failProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected file, can\'t be converted'**
  String get failProtected;

  /// No description provided for @failICloud.
  ///
  /// In en, this message translates to:
  /// **'Still downloading from iCloud'**
  String get failICloud;

  /// No description provided for @failNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on iPhone'**
  String get failNoSpace;

  /// No description provided for @failInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted before it finished'**
  String get failInterrupted;

  /// No description provided for @failUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Tunely can\'t read this file'**
  String get failUnreadable;

  /// No description provided for @failGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t convert this file'**
  String get failGeneric;

  /// No description provided for @pickerSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files selected'**
  String pickerSelectedCount(int count);

  /// No description provided for @pickerBatchProHint.
  ///
  /// In en, this message translates to:
  /// **'Select up to {count} files for a batch'**
  String pickerBatchProHint(int count);

  /// No description provided for @pickerMergeHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You can add 1 more file} other{You can add up to {count} more files}}'**
  String pickerMergeHint(int count);

  /// No description provided for @pickerLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can pick up to {count} files'**
  String pickerLimitReached(int count);

  /// No description provided for @mergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge audio'**
  String get mergeTitle;

  /// No description provided for @mergeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mergeAdd;

  /// No description provided for @mergeSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} files · {duration} total'**
  String mergeSummary(int count, String duration);

  /// No description provided for @mergeOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Plays in this order · drag to reorder'**
  String get mergeOrderHint;

  /// No description provided for @mergeCrossfade.
  ///
  /// In en, this message translates to:
  /// **'Crossfade between files'**
  String get mergeCrossfade;

  /// No description provided for @crossfadeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get crossfadeOff;

  /// No description provided for @crossfadeSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String crossfadeSeconds(int seconds);

  /// No description provided for @mergeSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get mergeSaveAs;

  /// No description provided for @mergeButton.
  ///
  /// In en, this message translates to:
  /// **'Merge {count} files'**
  String mergeButton(int count);

  /// No description provided for @mergeCaption.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} files · originals are not changed'**
  String mergeCaption(int min, int max);

  /// No description provided for @mergeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String mergeRemove(String name);

  /// No description provided for @mergeReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder {name}'**
  String mergeReorder(String name);

  /// No description provided for @mergePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview the merge'**
  String get mergePreview;

  /// No description provided for @mergePause.
  ///
  /// In en, this message translates to:
  /// **'Pause preview'**
  String get mergePause;

  /// No description provided for @mergeOutputName.
  ///
  /// In en, this message translates to:
  /// **'Tunely merge'**
  String get mergeOutputName;

  /// No description provided for @mergeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 files to merge.'**
  String get mergeEmpty;

  /// No description provided for @mergeConvertingTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} files merged into one'**
  String mergeConvertingTitle(int count);

  /// No description provided for @notifyPreviewApp.
  ///
  /// In en, this message translates to:
  /// **'Tunely'**
  String get notifyPreviewApp;

  /// No description provided for @notifyPreviewNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get notifyPreviewNow;

  /// No description provided for @notifyPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'8 files converted — tap to listen'**
  String get notifyPreviewBody;

  /// No description provided for @notifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Get a ping when it\'s done'**
  String get notifyTitle;

  /// No description provided for @notifyBody.
  ///
  /// In en, this message translates to:
  /// **'Big batches take a minute. Leave the app — we\'ll tell you when your files are ready. We also use this for the trial reminder we promised.'**
  String get notifyBody;

  /// No description provided for @notifyTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder before your trial ends'**
  String get notifyTrialTitle;

  /// No description provided for @notifyTrialBody.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications and we\'ll remind you a day before your trial ends. We also tell you when big batches are ready.'**
  String get notifyTrialBody;

  /// No description provided for @notifyTrialPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Your trial ends tomorrow — cancel anytime in Settings'**
  String get notifyTrialPreviewBody;

  /// No description provided for @notifyTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get notifyTurnOn;

  /// No description provided for @ratingTitleRingtone.
  ///
  /// In en, this message translates to:
  /// **'Your ringtone is ready!'**
  String get ratingTitleRingtone;

  /// No description provided for @ratingTitleAudio.
  ///
  /// In en, this message translates to:
  /// **'Your file is ready!'**
  String get ratingTitleAudio;

  /// No description provided for @ratingBody.
  ///
  /// In en, this message translates to:
  /// **'Enjoying Tunely? A quick rating helps other people find it.'**
  String get ratingBody;

  /// No description provided for @ratingRate.
  ///
  /// In en, this message translates to:
  /// **'Rate on the App Store'**
  String get ratingRate;

  /// No description provided for @ratingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Tell us what to improve'**
  String get ratingFeedback;

  /// No description provided for @ratingStars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String ratingStars(int count);

  /// No description provided for @feedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'Tunely feedback'**
  String get feedbackSubject;

  /// No description provided for @ratingThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the rating'**
  String get ratingThanks;

  /// No description provided for @updateVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String updateVersion(String version);

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'New in Tunely'**
  String get updateTitle;

  /// No description provided for @updateDefaultNote.
  ///
  /// In en, this message translates to:
  /// **'Improvements and bug fixes'**
  String get updateDefaultNote;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @milestoneEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Milestone unlocked'**
  String get milestoneEyebrow;

  /// No description provided for @milestoneFirstRingtone.
  ///
  /// In en, this message translates to:
  /// **'Your first ringtone!'**
  String get milestoneFirstRingtone;

  /// No description provided for @milestoneFirstRingtoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone sounds like you now. Send it to a friend — they\'ll want one too.'**
  String get milestoneFirstRingtoneBody;

  /// No description provided for @milestoneFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files made!'**
  String milestoneFiles(int count);

  /// No description provided for @milestoneFilesBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s {count} files converted right on your iPhone. Share your latest one with a friend.'**
  String milestoneFilesBody(int count);

  /// No description provided for @milestoneShareRingtone.
  ///
  /// In en, this message translates to:
  /// **'Share my ringtone'**
  String get milestoneShareRingtone;

  /// No description provided for @milestoneShareFile.
  ///
  /// In en, this message translates to:
  /// **'Share my file'**
  String get milestoneShareFile;

  /// No description provided for @shareCardTitleRingtone.
  ///
  /// In en, this message translates to:
  /// **'Share your ringtone'**
  String get shareCardTitleRingtone;

  /// No description provided for @shareCardTitleFile.
  ///
  /// In en, this message translates to:
  /// **'Share your file'**
  String get shareCardTitleFile;

  /// No description provided for @shareCardMetaRingtone.
  ///
  /// In en, this message translates to:
  /// **'My new ringtone · {duration}'**
  String shareCardMetaRingtone(String duration);

  /// No description provided for @shareCardMetaFile.
  ///
  /// In en, this message translates to:
  /// **'{format} · {duration}'**
  String shareCardMetaFile(String format, String duration);

  /// No description provided for @shareCardMadeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with Tunely'**
  String get shareCardMadeWith;

  /// No description provided for @shareAirDrop.
  ///
  /// In en, this message translates to:
  /// **'AirDrop'**
  String get shareAirDrop;

  /// No description provided for @shareMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get shareMessages;

  /// No description provided for @shareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareCopyLink;

  /// No description provided for @shareMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get shareMore;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @shareCardText.
  ///
  /// In en, this message translates to:
  /// **'Made with Tunely'**
  String get shareCardText;

  /// No description provided for @adBreakSavedAudio.
  ///
  /// In en, this message translates to:
  /// **'Your {format} is saved'**
  String adBreakSavedAudio(String format);

  /// No description provided for @adBreakSavedRingtone.
  ///
  /// In en, this message translates to:
  /// **'Your ringtone is saved'**
  String get adBreakSavedRingtone;

  /// No description provided for @adBreakBody.
  ///
  /// In en, this message translates to:
  /// **'A short ad helps keep Tunely free. You\'ll be right back here after it.'**
  String get adBreakBody;

  /// No description provided for @adBreakRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads with Pro'**
  String get adBreakRemoveAds;

  /// No description provided for @adsConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Tunely is free,\nthanks to a few ads'**
  String get adsConsentTitle;

  /// No description provided for @adsConsentBetweenTasks.
  ///
  /// In en, this message translates to:
  /// **'Ads appear only between tasks, never while converting.'**
  String get adsConsentBetweenTasks;

  /// No description provided for @adsConsentPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your files never leave your iPhone. Ads never see them.'**
  String get adsConsentPrivate;

  /// No description provided for @adsConsentTracking.
  ///
  /// In en, this message translates to:
  /// **'Next, iPhone asks if apps may track you to show more relevant ads. Either answer is fine; Tunely works the same.'**
  String get adsConsentTracking;

  /// No description provided for @adsConsentSeePro.
  ///
  /// In en, this message translates to:
  /// **'Prefer no ads? See Pro'**
  String get adsConsentSeePro;

  /// No description provided for @rewardedWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad for 1 more'**
  String get rewardedWatch;

  /// No description provided for @rewardedEarned.
  ///
  /// In en, this message translates to:
  /// **'+1 free conversion today'**
  String get rewardedEarned;

  /// No description provided for @moreAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'More from Marberx'**
  String get moreAppsTitle;

  /// No description provided for @moreAppsIntro.
  ///
  /// In en, this message translates to:
  /// **'Other Marberx apps. Get opens the App Store; Soon means the listing isn’t linked yet.'**
  String get moreAppsIntro;

  /// No description provided for @moreAppsPicked.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get moreAppsPicked;

  /// No description provided for @moreAppsAlso.
  ///
  /// In en, this message translates to:
  /// **'Also from us'**
  String get moreAppsAlso;

  /// No description provided for @moreAppsFooter.
  ///
  /// In en, this message translates to:
  /// **'Get opens the App Store. Soon means that app’s listing isn’t linked yet. No tracking, no rewards for installs.'**
  String get moreAppsFooter;

  /// No description provided for @moreAppsSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get moreAppsSoon;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adLabel;

  /// No description provided for @moreAppsGet.
  ///
  /// In en, this message translates to:
  /// **'Get {name}'**
  String moreAppsGet(String name);

  /// No description provided for @settingsMoreApps.
  ///
  /// In en, this message translates to:
  /// **'More Apps'**
  String get settingsMoreApps;

  /// No description provided for @houseCardEyebrow.
  ///
  /// In en, this message translates to:
  /// **'From the makers of Tunely'**
  String get houseCardEyebrow;

  /// No description provided for @houseCardShrinkVideo.
  ///
  /// In en, this message translates to:
  /// **'That video was {size}. Shrink makes videos smaller.'**
  String houseCardShrinkVideo(String size);

  /// No description provided for @houseCardView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get houseCardView;

  /// No description provided for @houseCardHide.
  ///
  /// In en, this message translates to:
  /// **'Hide this suggestion'**
  String get houseCardHide;

  /// No description provided for @galleryAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics events (latest first)'**
  String get galleryAnalytics;

  /// No description provided for @galleryAnalyticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events yet. Use the app and come back.'**
  String get galleryAnalyticsEmpty;

  /// No description provided for @galleryAnalyticsLive.
  ///
  /// In en, this message translates to:
  /// **'Sending to Mixpanel. Check Live View in the Tunely-Dev project.'**
  String get galleryAnalyticsLive;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @inviteBadge.
  ///
  /// In en, this message translates to:
  /// **'Both get 1 week Pro free'**
  String get inviteBadge;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends, get Pro free'**
  String get inviteTitle;

  /// No description provided for @inviteStep1.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get inviteStep1;

  /// No description provided for @inviteStep2.
  ///
  /// In en, this message translates to:
  /// **'Share your personal invite link'**
  String get inviteStep2;

  /// No description provided for @inviteStep3.
  ///
  /// In en, this message translates to:
  /// **'You both get 1 week of Pro when your friend makes their first file'**
  String get inviteStep3;

  /// No description provided for @inviteYourLink.
  ///
  /// In en, this message translates to:
  /// **'Your link'**
  String get inviteYourLink;

  /// No description provided for @invitePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your account only keeps your invite link and free weeks safe if you change phones. Your files never leave your iPhone.'**
  String get invitePrivacy;

  /// No description provided for @inviteCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create free account'**
  String get inviteCreateAccount;

  /// No description provided for @inviteHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get inviteHaveAccount;

  /// No description provided for @inviteSignedInBody.
  ///
  /// In en, this message translates to:
  /// **'Your friend gets a week of Pro right away. You get a week when they make their first file.'**
  String get inviteSignedInBody;

  /// No description provided for @inviteCodeLine.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String inviteCodeLine(String code);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @linkCopiedInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get linkCopiedInvite;

  /// No description provided for @statFriendsJoined.
  ///
  /// In en, this message translates to:
  /// **'Friends joined'**
  String get statFriendsJoined;

  /// No description provided for @statProEarned.
  ///
  /// In en, this message translates to:
  /// **'Pro earned'**
  String get statProEarned;

  /// No description provided for @statPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statPending;

  /// No description provided for @statDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String statDays(int count);

  /// No description provided for @inviteShare.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get inviteShare;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Get 1 week of Tunely Pro free with my invite: {link}'**
  String inviteShareText(String link);

  /// No description provided for @inviteCapReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached this year\'s invite limit. Your friends still get their week.'**
  String get inviteCapReached;

  /// No description provided for @inviteLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your invite stats.'**
  String get inviteLoadFailed;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save your invite link and rewards.'**
  String get signUpSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Convert and manage your media files easily.'**
  String get aboutTagline;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacy;

  /// No description provided for @aboutTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get aboutTerms;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get aboutContact;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get settingsAbout;

  /// No description provided for @fieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get fieldLastName;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a number'**
  String get passwordRule;

  /// No description provided for @signUpCodePreview.
  ///
  /// In en, this message translates to:
  /// **'Your invite code will be'**
  String get signUpCodePreview;

  /// No description provided for @signUpCodeLater.
  ///
  /// In en, this message translates to:
  /// **'Can change to a random code later'**
  String get signUpCodeLater;

  /// No description provided for @signUpCta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpCta;

  /// No description provided for @signUpTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to our '**
  String get signUpTermsPrefix;

  /// No description provided for @signUpTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signUpTermsAnd;

  /// No description provided for @termsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsLink;

  /// No description provided for @privacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyLink;

  /// No description provided for @signUpHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signUpHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// No description provided for @emailExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get emailExists;

  /// No description provided for @emailExistsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in instead?'**
  String get emailExistsSignIn;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your invite link and free weeks.'**
  String get signInSubtitle;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect. Try again or reset your password.'**
  String get signInError;

  /// No description provided for @signInLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in 15 minutes.'**
  String get signInLocked;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInCta;

  /// No description provided for @signInNew.
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get signInNew;

  /// No description provided for @signInCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get signInCreate;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with. We\'ll send you a link to set a new password.'**
  String get resetBody;

  /// No description provided for @resetCta.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetCta;

  /// No description provided for @resetSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get resetSentTitle;

  /// No description provided for @resetSentPrefix.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for '**
  String get resetSentPrefix;

  /// No description provided for @resetSentSuffix.
  ///
  /// In en, this message translates to:
  /// **', you\'ll get a reset link in a few minutes. Check your spam folder too.'**
  String get resetSentSuffix;

  /// No description provided for @resetBack.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get resetBack;

  /// No description provided for @resetResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String resetResendIn(String time);

  /// No description provided for @resetResend.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resetResend;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @fieldTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use 50 characters or fewer'**
  String get fieldTooLong;

  /// No description provided for @fieldEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get fieldEmailInvalid;

  /// No description provided for @fieldPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a number'**
  String get fieldPasswordWeak;

  /// No description provided for @accountOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet and try again.'**
  String get accountOffline;

  /// No description provided for @accountServerError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Your details are still here, try again.'**
  String get accountServerError;

  /// No description provided for @accountValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields and try again.'**
  String get accountValidationError;

  /// No description provided for @tryAgain2.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain2;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @verifyBannerBold.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyBannerBold;

  /// No description provided for @verifyBannerRest.
  ///
  /// In en, this message translates to:
  /// **' to receive your free weeks. We sent a link to {email}.'**
  String verifyBannerRest(String email);

  /// No description provided for @verifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get verifyResend;

  /// No description provided for @verifySent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verifySent;

  /// No description provided for @accountInviteRewards.
  ///
  /// In en, this message translates to:
  /// **'Invite & rewards'**
  String get accountInviteRewards;

  /// No description provided for @accountYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get accountYourCode;

  /// No description provided for @accountRandomCode.
  ///
  /// In en, this message translates to:
  /// **'Use random code'**
  String get accountRandomCode;

  /// No description provided for @accountRandomTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to a random code?'**
  String get accountRandomTitle;

  /// No description provided for @accountRandomBody.
  ///
  /// In en, this message translates to:
  /// **'Your current code and link stop working for new friends. You can only do this once.'**
  String get accountRandomBody;

  /// No description provided for @accountRandomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get accountRandomConfirm;

  /// No description provided for @accountFreeEarned.
  ///
  /// In en, this message translates to:
  /// **'Free Pro earned'**
  String get accountFreeEarned;

  /// No description provided for @accountInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get accountInvite;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get accountSecurity;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountChangePassword;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutTitle;

  /// No description provided for @accountSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Tunely keeps working and your Pro is not affected. Sign in again any time to see your invites.'**
  String get accountSignOutBody;

  /// No description provided for @accountProNote.
  ///
  /// In en, this message translates to:
  /// **'Your Pro subscription is linked to your Apple ID, not this account. Manage it in Settings › Apple ID › Subscriptions.'**
  String get accountProNote;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get fieldCurrentPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  /// No description provided for @changePasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'That password is not right'**
  String get changePasswordWrong;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @deleteTitle2.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteTitle2;

  /// No description provided for @deleteGone.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted'**
  String get deleteGone;

  /// No description provided for @deleteGoneAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account ({name}, {email})'**
  String deleteGoneAccount(String name, String email);

  /// No description provided for @deleteGoneCode.
  ///
  /// In en, this message translates to:
  /// **'Your invite code {code} and link'**
  String deleteGoneCode(String code);

  /// No description provided for @deleteGoneDays.
  ///
  /// In en, this message translates to:
  /// **'Free Pro weeks not yet used'**
  String get deleteGoneDays;

  /// No description provided for @deleteKept.
  ///
  /// In en, this message translates to:
  /// **'Not affected'**
  String get deleteKept;

  /// No description provided for @deleteKeptFiles.
  ///
  /// In en, this message translates to:
  /// **'Your files in Tunely and in your Tunely folder'**
  String get deleteKeptFiles;

  /// No description provided for @deleteKeptPro.
  ///
  /// In en, this message translates to:
  /// **'Your Pro subscription — cancel it separately in Settings › Apple ID › Subscriptions'**
  String get deleteKeptPro;

  /// No description provided for @deletePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deletePasswordLabel;

  /// No description provided for @deleteKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get deleteKeep;

  /// No description provided for @deleteDone.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted'**
  String get deleteDone;

  /// No description provided for @redeemTitle.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get redeemTitle;

  /// No description provided for @redeemBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a friend\'s code to get 1 week of Pro free. No account needed.'**
  String get redeemBody;

  /// No description provided for @redeemLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get redeemLabel;

  /// No description provided for @redeemFromLink.
  ///
  /// In en, this message translates to:
  /// **'Added from your friend\'s link'**
  String get redeemFromLink;

  /// No description provided for @redeemInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code isn\'t valid, or an invite was already used on this iPhone.'**
  String get redeemInvalid;

  /// No description provided for @redeemValidCode.
  ///
  /// In en, this message translates to:
  /// **'Valid invite code'**
  String get redeemValidCode;

  /// No description provided for @redeemInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code'**
  String get redeemInvalidCode;

  /// No description provided for @redeemCodeMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Invite code can contain a maximum of 10 characters.'**
  String get redeemCodeMaxLength;

  /// No description provided for @redeemCta.
  ///
  /// In en, this message translates to:
  /// **'Apply code'**
  String get redeemCta;

  /// No description provided for @redeemSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get redeemSkip;

  /// No description provided for @redeemSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'1 week of Pro unlocked'**
  String get redeemSuccessTitle;

  /// No description provided for @redeemSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'A gift from {name}. Enjoy unlimited conversions, all formats and merge until {date}.'**
  String redeemSuccessBody(String name, String date);

  /// No description provided for @redeemSuccessHint.
  ///
  /// In en, this message translates to:
  /// **'Make your first file and {name} gets a free week too.'**
  String redeemSuccessHint(String name);

  /// No description provided for @redeemAlreadyPro.
  ///
  /// In en, this message translates to:
  /// **'You\'re already Pro — your friend still gets their reward when you make your first file.'**
  String get redeemAlreadyPro;

  /// No description provided for @redeemMakeFile.
  ///
  /// In en, this message translates to:
  /// **'Make a file'**
  String get redeemMakeFile;

  /// No description provided for @redeemFriend.
  ///
  /// In en, this message translates to:
  /// **'your friend'**
  String get redeemFriend;

  /// No description provided for @settingsAccountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create account'**
  String get settingsAccountSignedOut;

  /// No description provided for @settingsAccountOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional · only for invite rewards'**
  String get settingsAccountOptional;

  /// No description provided for @settingsInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get settingsInvite;

  /// No description provided for @settingsInviteDetail.
  ///
  /// In en, this message translates to:
  /// **'Both get 1 week Pro'**
  String get settingsInviteDetail;

  /// No description provided for @settingsHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get settingsHaveCode;

  /// No description provided for @onboardingInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Got an invite code?'**
  String get onboardingInviteCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
