import '../../l10n/app_localizations.dart';

/// Help & FAQ content from `docs/handoff/15_Help_FAQ.md`. The slug is the
/// `help_article_opened` property (`08`).
class FaqEntry {
  const FaqEntry(this.slug, this.question, this.answer);

  final String slug;
  final String question;
  final String answer;
}

/// The first [featuredCount] entries are listed on screen 25; all are searchable.
const featuredCount = 7;

List<FaqEntry> faqEntries(AppLocalizations l10n) => [
  FaqEntry('ads', l10n.faqAdsQ, l10n.faqAdsA),
  FaqEntry('set-ringtone', l10n.faqSetRingtoneQ, l10n.faqSetRingtoneA),
  FaqEntry('drm', l10n.faqDrmQ, l10n.faqDrmA),
  FaqEntry('quality', l10n.faqQualityQ, l10n.faqQualityA),
  FaqEntry('where-saved', l10n.faqWhereSavedQ, l10n.faqWhereSavedA),
  FaqEntry(
    'free-conversions',
    l10n.faqFreeConversionsQ,
    l10n.faqFreeConversionsA,
  ),
  FaqEntry('cancel', l10n.faqCancelQ, l10n.faqCancelA),
  FaqEntry(
    'what-can-i-convert',
    l10n.faqWhatCanIConvertQ,
    l10n.faqWhatCanIConvertA,
  ),
  FaqEntry('video-to-mp3', l10n.faqVideoToMp3Q, l10n.faqVideoToMp3A),
  FaqEntry('privacy', l10n.faqPrivacyQ, l10n.faqPrivacyA),
  FaqEntry('offline', l10n.faqOfflineQ, l10n.faqOfflineA),
  FaqEntry('no-audio', l10n.faqNoAudioQ, l10n.faqNoAudioA),
  FaqEntry('icloud', l10n.faqIcloudQ, l10n.faqIcloudA),
  FaqEntry(
    'conversion-failed',
    l10n.faqConversionFailedQ,
    l10n.faqConversionFailedA,
  ),
  FaqEntry('storage', l10n.faqStorageQ, l10n.faqStorageA),
  FaqEntry('background', l10n.faqBackgroundQ, l10n.faqBackgroundA),
  FaqEntry('ringtone-length', l10n.faqRingtoneLengthQ, l10n.faqRingtoneLengthA),
  FaqEntry(
    'alarm-text-tones',
    l10n.faqAlarmTextTonesQ,
    l10n.faqAlarmTextTonesA,
  ),
  FaqEntry(
    'ringtone-missing',
    l10n.faqRingtoneMissingQ,
    l10n.faqRingtoneMissingA,
  ),
  FaqEntry('trim-fade', l10n.faqTrimFadeQ, l10n.faqTrimFadeA),
  FaqEntry('merge', l10n.faqMergeQ, l10n.faqMergeA),
  FaqEntry('batch', l10n.faqBatchQ, l10n.faqBatchA),
  FaqEntry('volume-boost', l10n.faqVolumeBoostQ, l10n.faqVolumeBoostA),
  FaqEntry('pro', l10n.faqProQ, l10n.faqProA),
  FaqEntry('trial', l10n.faqTrialQ, l10n.faqTrialA),
  FaqEntry('restore', l10n.faqRestoreQ, l10n.faqRestoreA),
  FaqEntry('refund', l10n.faqRefundQ, l10n.faqRefundA),
  FaqEntry('devices', l10n.faqDevicesQ, l10n.faqDevicesA),
  FaqEntry('delete', l10n.faqDeleteQ, l10n.faqDeleteA),
  FaqEntry('rename', l10n.faqRenameQ, l10n.faqRenameA),
  FaqEntry('folder-missing', l10n.faqFolderMissingQ, l10n.faqFolderMissingA),
  // Account / invite / redeem UI hidden until referral API is ready.
  // FaqEntry('account', l10n.faqAccountQ, l10n.faqAccountA),
  // FaqEntry('invites', l10n.faqInvitesQ, l10n.faqInvitesA),
  // FaqEntry('invite-code', l10n.faqInviteCodeQ, l10n.faqInviteCodeA),
  // FaqEntry('delete-account', l10n.faqDeleteAccountQ, l10n.faqDeleteAccountA),
  FaqEntry('tracking', l10n.faqTrackingQ, l10n.faqTrackingA),
  FaqEntry('remove-ads', l10n.faqRemoveAdsQ, l10n.faqRemoveAdsA),
  FaqEntry('more-apps', l10n.faqMoreAppsQ, l10n.faqMoreAppsA),
];
