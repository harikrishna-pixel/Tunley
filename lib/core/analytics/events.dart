import 'analytics.dart';

/// Event names exactly as in `08_Analytics_Events.md`.
abstract final class Events {
  // Onboarding & app.
  static const appOpened = 'app_opened';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const onboardingQuestionAnswered = 'onboarding_question_answered';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingSkipped = 'onboarding_skipped';
  static const preferencesChanged = 'preferences_changed';
  static const permissionRequested = 'permission_requested';
  static const permissionResult = 'permission_result';

  // Core flow.
  static const toolSelected = 'tool_selected';
  static const filePicked = 'file_picked';
  static const settingsChanged = 'settings_changed';
  static const trimApplied = 'trim_applied';
  static const taskStarted = 'task_started';
  static const taskCompleted = 'task_completed';
  static const taskFailed = 'task_failed';
  static const taskCancelled = 'task_cancelled';
  static const backgroundUsed = 'background_used';
  static const filePlayed = 'file_played';
  static const fileSaved = 'file_saved';
  static const saveFolderChosen = 'save_folder_chosen';
  static const fileShared = 'file_shared';
  static const fileRenamed = 'file_renamed';
  static const fileDeleted = 'file_deleted';
  static const batchStarted = 'batch_started';
  static const batchCompleted = 'batch_completed';
  static const mergeStarted = 'merge_started';
  static const mergeCompleted = 'merge_completed';
  static const backgroundInterrupted = 'background_interrupted';
  static const jobResumed = 'job_resumed';

  // Ringtone.
  static const ringtoneCreated = 'ringtone_created';
  static const guideOpened = 'guide_opened';
  static const guideStepViewed = 'guide_step_viewed';
  static const guideShareOpened = 'guide_share_opened';
  static const guideCompleted = 'guide_completed';
  static const garagebandGuideOpened = 'garageband_guide_opened';

  // Monetization.
  static const paywallViewed = 'paywall_viewed';
  static const paywallClosed = 'paywall_closed';
  static const planSelected = 'plan_selected';
  static const purchaseStarted = 'purchase_started';
  static const trialStarted = 'trial_started';
  static const purchaseSucceeded = 'purchase_succeeded';
  static const purchaseFailed = 'purchase_failed';
  static const purchaseCancelled = 'purchase_cancelled';
  static const purchasePending = 'purchase_pending';
  static const purchaseOffline = 'purchase_offline';
  static const restoreTapped = 'restore_tapped';
  static const restoreResult = 'restore_result';
  static const limitReached = 'limit_reached';
  static const proFeatureTapped = 'pro_feature_tapped';
  static const freeAlternativeUsed = 'free_alternative_used';
  static const exitOfferShown = 'exit_offer_shown';
  static const exitOfferAccepted = 'exit_offer_accepted';
  static const exitOfferExpired = 'exit_offer_expired';
  static const trialReminderScheduled = 'trial_reminder_scheduled';
  static const trialReminderOpened = 'trial_reminder_opened';
  static const manageSubscriptionTapped = 'manage_subscription_tapped';
  static const winbackShown = 'winback_shown';
  static const winbackAccepted = 'winback_accepted';

  // Ads and cross-promotion.
  static const adBreakShown = 'ad_break_shown';
  static const adBreakContinue = 'ad_break_continue';
  static const adRequested = 'ad_requested';
  static const adLoaded = 'ad_loaded';
  static const adFailed = 'ad_failed';
  static const adShown = 'ad_shown';
  static const adClosed = 'ad_closed';
  static const adClicked = 'ad_clicked';
  static const rewardedOffered = 'rewarded_offered';
  static const rewardedEarned = 'rewarded_earned';
  static const removeAdsTapped = 'remove_ads_tapped';
  static const trackingPromptShown = 'tracking_prompt_shown';
  static const trackingResult = 'tracking_result';
  static const consentResult = 'consent_result';
  static const houseCardShown = 'house_card_shown';
  static const houseCardTapped = 'house_card_tapped';
  static const houseCardHidden = 'house_card_hidden';
  static const moreAppsOpened = 'more_apps_opened';
  static const moreAppsTapped = 'more_apps_tapped';

  // Self-marketing & prompts.
  static const ratingPromptShown = 'rating_prompt_shown';
  static const ratingPromptAnswered = 'rating_prompt_answered';
  static const feedbackSent = 'feedback_sent';
  static const notificationPromptShown = 'notification_prompt_shown';
  static const milestoneReached = 'milestone_reached';
  static const shareCardOpened = 'share_card_opened';
  static const updatePromptShown = 'update_prompt_shown';
  static const updateTapped = 'update_tapped';
  static const helpArticleOpened = 'help_article_opened';
  static const supportContacted = 'support_contacted';

  // Errors.
  static const errorShown = 'error_shown';
  static const errorRecoveryAction = 'error_recovery_action';
  static const batchRetryTapped = 'batch_retry_tapped';

  // Account and referral.
  static const inviteEntryOpened = 'invite_entry_opened';
  static const signupStarted = 'signup_started';
  static const signupCompleted = 'signup_completed';
  static const signupFailed = 'signup_failed';
  static const loginCompleted = 'login_completed';
  static const loginFailed = 'login_failed';
  static const passwordResetRequested = 'password_reset_requested';
  static const emailVerified = 'email_verified';
  static const accountDeleted = 'account_deleted';
  static const inviteLinkShared = 'invite_link_shared';
  static const inviteCodeRedeemed = 'invite_code_redeemed';
  static const referralQualified = 'referral_qualified';
  static const referralRewarded = 'referral_rewarded';
}

/// Megabytes with one decimal (`08` › Rules).
double mb(num bytes) => (bytes / 1048576 * 10).round() / 10;

/// Seconds with one decimal.
double secs(num seconds) => (seconds * 10).round() / 10;

/// One typed helper per event with exactly the properties in `08`.
extension TunelyEvents on Analytics {
  // Onboarding & app.
  void appOpened({required String source}) =>
      track(Events.appOpened, {'source': source});

  void onboardingStepViewed({required int step}) =>
      track(Events.onboardingStepViewed, {'step': step});

  void onboardingQuestionAnswered({
    required String question,
    required String answer,
  }) => track(Events.onboardingQuestionAnswered, {
    'question': question,
    'answer': answer,
  });

  void onboardingCompleted({required num durationS}) =>
      track(Events.onboardingCompleted, {'duration_s': secs(durationS)});

  void onboardingSkipped({required int step}) =>
      track(Events.onboardingSkipped, {'step': step});

  void preferencesChanged({required String field, required String value}) =>
      track(Events.preferencesChanged, {'field': field, 'value': value});

  void permissionRequested({String type = 'notifications'}) =>
      track(Events.permissionRequested, {'type': type});

  void permissionResult({
    String type = 'notifications',
    required bool granted,
  }) => track(Events.permissionResult, {'type': type, 'granted': granted});

  // Core flow.
  void toolSelected({required String tool, required String entry}) =>
      track(Events.toolSelected, {'tool': tool, 'entry': entry});

  void filePicked({
    required String source,
    required String type,
    required int count,
    required num durationS,
    required num sizeMb,
  }) => track(Events.filePicked, {
    'source': source,
    'type': type,
    'count': count,
    'duration_s': secs(durationS),
    'size_mb': sizeMb,
  });

  void settingsChanged({
    required String format,
    required String quality,
    required String mode,
    String? toneType,
  }) => track(Events.settingsChanged, {
    'format': format,
    'quality': quality,
    'mode': mode,
    'tone_type': toneType,
  });

  void trimApplied({
    required num lengthS,
    required num fadeInS,
    required num fadeOutS,
    required num boostDb,
  }) => track(Events.trimApplied, {
    'length_s': secs(lengthS),
    'fade_in_s': fadeInS,
    'fade_out_s': fadeOutS,
    'boost_db': boostDb,
  });

  void taskStarted({
    required String task,
    required String format,
    required String quality,
    required String mode,
    required String inputType,
    required num durationS,
    required num estSizeMb,
  }) => track(Events.taskStarted, {
    'task': task,
    'format': format,
    'quality': quality,
    'mode': mode,
    'input_type': inputType,
    'duration_s': secs(durationS),
    'est_size_mb': estSizeMb,
  });

  void taskCompleted({
    required String task,
    required String format,
    required String quality,
    required String mode,
    required num sizeMb,
    required num secondsTaken,
    required num durationS,
    int? freeLeft,
  }) => track(Events.taskCompleted, {
    'task': task,
    'format': format,
    'quality': quality,
    'mode': mode,
    'size_mb': sizeMb,
    'seconds_taken': secs(secondsTaken),
    'duration_s': secs(durationS),
    'free_left': freeLeft,
  });

  void taskFailed({
    required String task,
    required String errorType,
    required int progressPct,
    required String format,
  }) => track(Events.taskFailed, {
    'task': task,
    'error_type': errorType,
    'progress_pct': progressPct,
    'format': format,
  });

  void taskCancelled({required int progressPct}) =>
      track(Events.taskCancelled, {'progress_pct': progressPct});

  void backgroundUsed({required String task}) =>
      track(Events.backgroundUsed, {'task': task});

  void filePlayed({required String screen}) =>
      track(Events.filePlayed, {'screen': screen});

  void fileSaved({required String destination, required String format}) =>
      track(Events.fileSaved, {'destination': destination, 'format': format});

  void saveFolderChosen({required bool? isIcloud}) =>
      track(Events.saveFolderChosen, {'is_icloud': isIcloud});

  void fileShared({
    required String target,
    required String format,
    required String screen,
  }) => track(Events.fileShared, {
    'target': target,
    'format': format,
    'screen': screen,
  });

  void fileRenamed({required String format}) =>
      track(Events.fileRenamed, {'format': format});

  void fileDeleted({required String format}) =>
      track(Events.fileDeleted, {'format': format});

  void batchStarted({required int count, required String format}) =>
      track(Events.batchStarted, {'count': count, 'format': format});

  void batchCompleted({
    required int count,
    required int failedCount,
    required num secondsTaken,
  }) => track(Events.batchCompleted, {
    'count': count,
    'failed_count': failedCount,
    'seconds_taken': secs(secondsTaken),
  });

  void mergeStarted({
    required int count,
    required int crossfadeS,
    required String format,
  }) => track(Events.mergeStarted, {
    'count': count,
    'crossfade_s': crossfadeS,
    'format': format,
  });

  void mergeCompleted({
    required int count,
    required num lengthS,
    required num secondsTaken,
  }) => track(Events.mergeCompleted, {
    'count': count,
    'length_s': secs(lengthS),
    'seconds_taken': secs(secondsTaken),
  });

  void backgroundInterrupted({
    required String task,
    required int progressPct,
    required int iosMajor,
  }) => track(Events.backgroundInterrupted, {
    'task': task,
    'progress_pct': progressPct,
    'ios_major': iosMajor,
  });

  void jobResumed({required String task}) =>
      track(Events.jobResumed, {'task': task});

  // Ringtone.
  void ringtoneCreated({
    required String toneType,
    required num lengthS,
    required num fadeInS,
    required num fadeOutS,
  }) => track(Events.ringtoneCreated, {
    'tone_type': toneType,
    'length_s': secs(lengthS),
    'fade_in_s': fadeInS,
    'fade_out_s': fadeOutS,
  });

  void guideOpened({required String entry, required String iosVersion}) =>
      track(Events.guideOpened, {'entry': entry, 'ios_version': iosVersion});

  void guideStepViewed({required int step, required String iosVersion}) =>
      track(Events.guideStepViewed, {'step': step, 'ios_version': iosVersion});

  void guideShareOpened({required String iosVersion}) =>
      track(Events.guideShareOpened, {'ios_version': iosVersion});

  void guideCompleted({required String iosVersion}) =>
      track(Events.guideCompleted, {'ios_version': iosVersion});

  void garagebandGuideOpened({required String iosVersion}) =>
      track(Events.garagebandGuideOpened, {'ios_version': iosVersion});

  // Monetization.
  void paywallViewed({
    required String trigger,
    required String variant,
    required String goal,
    required bool trialEligible,
    String? feature,
  }) => track(Events.paywallViewed, {
    'trigger': trigger,
    'variant': variant,
    'goal': goal,
    'trial_eligible': trialEligible,
    'feature': feature,
  });

  void paywallClosed({required String trigger, required num secondsOnScreen}) =>
      track(Events.paywallClosed, {
        'trigger': trigger,
        'seconds_on_screen': secs(secondsOnScreen),
      });

  void planSelected({required String plan, required String trigger}) =>
      track(Events.planSelected, {'plan': plan, 'trigger': trigger});

  void purchaseStarted({
    required String plan,
    required String trigger,
    required num price,
    required String currency,
  }) => track(Events.purchaseStarted, {
    'plan': plan,
    'trigger': trigger,
    'price': price,
    'currency': currency,
  });

  void trialStarted({required String plan, required String trigger}) =>
      track(Events.trialStarted, {'plan': plan, 'trigger': trigger});

  void purchaseSucceeded({
    required String plan,
    required String trigger,
    required num price,
    required String currency,
  }) => track(Events.purchaseSucceeded, {
    'plan': plan,
    'trigger': trigger,
    'price': price,
    'currency': currency,
  });

  void purchaseFailed({
    required String plan,
    required String trigger,
    required String errorCode,
  }) => track(Events.purchaseFailed, {
    'plan': plan,
    'trigger': trigger,
    'error_code': errorCode,
  });

  void purchaseCancelled({required String plan, required String trigger}) =>
      track(Events.purchaseCancelled, {'plan': plan, 'trigger': trigger});

  void purchasePending({required String plan}) =>
      track(Events.purchasePending, {'plan': plan});

  void purchaseOffline({required String action}) =>
      track(Events.purchaseOffline, {'action': action});

  void restoreTapped() => track(Events.restoreTapped);

  void restoreResult({required String result, String? plan}) =>
      track(Events.restoreResult, {'result': result, 'plan': plan});

  void limitReached({String type = 'daily', required int usedToday}) =>
      track(Events.limitReached, {'type': type, 'used_today': usedToday});

  void proFeatureTapped({required String feature}) =>
      track(Events.proFeatureTapped, {'feature': feature});

  void freeAlternativeUsed({required String feature}) =>
      track(Events.freeAlternativeUsed, {'feature': feature});

  void exitOfferShown({required int secondsLeft}) =>
      track(Events.exitOfferShown, {'seconds_left': secondsLeft});

  void exitOfferAccepted({required int secondsLeft}) =>
      track(Events.exitOfferAccepted, {'seconds_left': secondsLeft});

  void exitOfferExpired({int secondsLeft = 0}) =>
      track(Events.exitOfferExpired, {'seconds_left': secondsLeft});

  void trialReminderScheduled({required int hoursBeforeEnd}) => track(
    Events.trialReminderScheduled,
    {'hours_before_end': hoursBeforeEnd},
  );

  void trialReminderOpened({required String entry}) =>
      track(Events.trialReminderOpened, {'entry': entry});

  void manageSubscriptionTapped({required String screen}) =>
      track(Events.manageSubscriptionTapped, {'screen': screen});

  void winbackShown({required int? daysSinceLapse}) =>
      track(Events.winbackShown, {'days_since_lapse': daysSinceLapse});

  void winbackAccepted({required int? daysSinceLapse}) =>
      track(Events.winbackAccepted, {'days_since_lapse': daysSinceLapse});

  // Ads and cross-promotion.
  void adBreakShown({required String trigger, required int conversionsToday}) =>
      track(Events.adBreakShown, {
        'trigger': trigger,
        'conversions_today': conversionsToday,
      });

  void adBreakContinue() => track(Events.adBreakContinue);

  void adRequested({required String format, required String provider}) =>
      track(Events.adRequested, {'format': format, 'provider': provider});

  void adLoaded({required String format, required String provider}) =>
      track(Events.adLoaded, {'format': format, 'provider': provider});

  void adFailed({
    required String format,
    required String provider,
    required String reason,
  }) => track(Events.adFailed, {
    'format': format,
    'provider': provider,
    'reason': reason,
  });

  void adShown({
    required String format,
    required String provider,
    String? network,
  }) => track(Events.adShown, {
    'format': format,
    'provider': provider,
    'network': network,
  });

  void adClosed({required String format, required String provider}) =>
      track(Events.adClosed, {'format': format, 'provider': provider});

  void adClicked({required String format, required String provider}) =>
      track(Events.adClicked, {'format': format, 'provider': provider});

  void rewardedOffered({required int rewardedToday}) =>
      track(Events.rewardedOffered, {'rewarded_today': rewardedToday});

  void rewardedEarned({required int rewardedToday}) =>
      track(Events.rewardedEarned, {'rewarded_today': rewardedToday});

  void removeAdsTapped({required String screen}) =>
      track(Events.removeAdsTapped, {'screen': screen});

  void trackingPromptShown() => track(Events.trackingPromptShown);

  void trackingResult({required String status}) =>
      track(Events.trackingResult, {'status': status});

  void consentResult({required String status}) =>
      track(Events.consentResult, {'status': status});

  void houseCardShown({required String app, required String screen}) =>
      track(Events.houseCardShown, {'app': app, 'screen': screen});

  void houseCardTapped({required String app, required String screen}) =>
      track(Events.houseCardTapped, {'app': app, 'screen': screen});

  void houseCardHidden({required String app, required String screen}) =>
      track(Events.houseCardHidden, {'app': app, 'screen': screen});

  void moreAppsOpened({required String entry}) =>
      track(Events.moreAppsOpened, {'entry': entry});

  void moreAppsTapped({
    required String app,
    required int position,
    required String screen,
  }) => track(Events.moreAppsTapped, {
    'app': app,
    'position': position,
    'screen': screen,
  });

  // Self-marketing & prompts.
  void ratingPromptShown({required String trigger, required int timesShown}) =>
      track(Events.ratingPromptShown, {
        'trigger': trigger,
        'times_shown': timesShown,
      });

  void ratingPromptAnswered({required int stars, required String routedTo}) =>
      track(Events.ratingPromptAnswered, {
        'stars': stars,
        'routed_to': routedTo,
      });

  void feedbackSent() => track(Events.feedbackSent);

  void notificationPromptShown({required String context}) =>
      track(Events.notificationPromptShown, {'context': context});

  void milestoneReached({required String name}) =>
      track(Events.milestoneReached, {'name': name});

  void shareCardOpened({required String entry}) =>
      track(Events.shareCardOpened, {'entry': entry});

  void updatePromptShown({required String version}) =>
      track(Events.updatePromptShown, {'version': version});

  void updateTapped({required String version}) =>
      track(Events.updateTapped, {'version': version});

  void helpArticleOpened({required String article}) =>
      track(Events.helpArticleOpened, {'article': article});

  void supportContacted({required String screen}) =>
      track(Events.supportContacted, {'screen': screen});

  // Errors.
  void errorShown({required String type, required String code}) =>
      track(Events.errorShown, {'type': type, 'code': code});

  void errorRecoveryAction({required String type, required String action}) =>
      track(Events.errorRecoveryAction, {'type': type, 'action': action});

  void batchRetryTapped({required int count}) =>
      track(Events.batchRetryTapped, {'count': count});

  // Account and referral (never email or name).
  void inviteEntryOpened({required String source, required bool signedIn}) =>
      track(Events.inviteEntryOpened, {
        'source': source,
        'signed_in': signedIn,
      });

  void signupStarted() => track(Events.signupStarted);

  void signupCompleted() => track(Events.signupCompleted);

  void signupFailed({required String error}) =>
      track(Events.signupFailed, {'error': error});

  void loginCompleted() => track(Events.loginCompleted);

  void loginFailed({required String error}) =>
      track(Events.loginFailed, {'error': error});

  void passwordResetRequested() => track(Events.passwordResetRequested);

  void emailVerified() => track(Events.emailVerified);

  void accountDeleted() => track(Events.accountDeleted);

  void inviteLinkShared({String? channel}) =>
      track(Events.inviteLinkShared, {'channel': channel});

  void inviteCodeRedeemed({required String source, required String result}) =>
      track(Events.inviteCodeRedeemed, {'source': source, 'result': result});

  void referralQualified() => track(Events.referralQualified);

  void referralRewarded() => track(Events.referralRewarded);
}
