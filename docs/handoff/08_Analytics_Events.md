# 08 · Analytics Events

## Platform

| Layer | Tool | Why |
|-------|------|-----|
| Product analytics | **Mixpanel** (recommended, `mixpanel_flutter`) | Funnels, retention, cohorts; free tier up to 1M events/month; has an official Claude connector so Praba can ask questions about the data directly |
| Revenue | **RevenueCat** | Trials, conversions, renewals, refunds, MRR (source of truth for money) |
| Crashes | Firebase Crashlytics | Crash-free rate, stack traces |

Alternatives if Praba prefers: Amplitude or PostHog (both have Claude connectors), TelemetryDeck (privacy-first, no connector). **Code never calls a vendor SDK directly.** Everything goes through one `Analytics` service (`lib/core/analytics/`), so the provider can be swapped by changing one class.

Integrations: send RevenueCat events to Mixpanel (RevenueCat → Integrations → Mixpanel) so paywall views and purchases sit in the same funnel. Set Mixpanel `distinct_id` = RevenueCat `appUserID`.

## Rules

- **Naming:** `object_action`, snake_case, past tense (`paywall_viewed`, `task_completed`). Properties snake_case.
- **No personal data:** no file names, paths, titles, emails, IP storage (enable Mixpanel "ignore IP"), no free-text from feedback.
- **One event per real action**, fired after it succeeded (e.g. `file_saved` after the write finished).
- **Every event gets super properties automatically:** `app_version`, `ios_version`, `is_pro`, `plan`, `goal`, `frequency`, `theme` (light/dark), `session_number`.
- Durations in seconds (number), sizes in MB (1 decimal), percentages 0–100.
- Debug builds send to a separate Mixpanel project (`Tunely-Dev`).

## User properties (set / update)

| Property | Values | Set when |
|----------|--------|----------|
| `goal` | ringtone · mp3 · convert | O2 answer, Preferences change |
| `frequency` | daily · weekly · rarely | O3 answer, Preferences change |
| `is_pro` | true / false | Launch, entitlement change |
| `plan` | none · trial · weekly · yearly · yearly_exit · yearly_winback · lifetime | Entitlement change |
| `first_open_date` | ISO date | First launch (set once) |
| `files_made_total` | number | After each `task_completed` (increment) |
| `ringtones_made_total` | number | After each ringtone |
| `notifications_enabled` | true / false | Permission result |
| `ios_major` | 16…26 | Launch |

## Event table

### Onboarding & app

| Event | Trigger | Properties | Screen |
|-------|---------|------------|--------|
| `app_opened` | Every launch / foreground after 30 min | `source` (icon · notification · share · deeplink) | – |
| `onboarding_step_viewed` | Each onboarding screen appears | `step` (1–5) | 01–05 |
| `onboarding_question_answered` | Continue on O2 / O3 | `question` (goal · frequency), `answer` | 02, 03 |
| `onboarding_completed` | Get started on O5 | `duration_s` | 05 |
| `onboarding_skipped` | Skip tapped | `step` | 01–04 |
| `preferences_changed` | Change in Your preferences / Settings | `field` (goal · frequency · default_format · save_folder), `value` | 23, 24 |
| `permission_requested` | System notification prompt shown | `type` (notifications) | 27 |
| `permission_result` | User answered | `type`, `granted` | 27 |

### Core flow

| Event | Trigger | Properties | Screen |
|-------|---------|------------|--------|
| `tool_selected` | Hero CTA or tool tile tapped | `tool` (ringtone · video_to_mp3 · convert · trim · merge · boost · batch), `entry` (hero · tile · recent) | 06 |
| `file_picked` | File(s) confirmed in picker | `source` (photos · files · recent · share), `type` (video · audio), `count`, `duration_s` (first file), `size_mb` | 07 |
| `settings_changed` | Format / quality / mode changed on Convert | `format`, `quality` (standard · high · best · custom), `mode` (audio · ringtone), `tone_type` | 08 |
| `trim_applied` | Done on Trim & fade | `length_s`, `fade_in_s`, `fade_out_s`, `boost_db` | 19 |
| `task_started` | Convert / Create ringtone / Merge tapped and pre-flight passed | `task` (convert · ringtone · merge), `format`, `quality`, `mode`, `input_type`, `duration_s`, `est_size_mb` | 08 |
| `task_completed` | Output file written | `task`, `format`, `quality`, `mode`, `size_mb`, `seconds_taken`, `duration_s`, `free_left` (free users) | 18 → 09 |
| `task_failed` | Engine error | `task`, `error_type` (decode · encode · io · interrupted · vfr · unknown), `progress_pct`, `format` | 18 → 32 |
| `task_cancelled` | Stop confirmed | `progress_pct` | 37 |
| `background_used` | Run in background tapped | `task` (single · batch) | 18, 21 |
| `file_played` | Play tapped | `screen` (result · my_files · trim) | 09, 19, 22 |
| `file_saved` | Saved to Tunely folder / Files | `destination` (tunely_folder · files_other), `format` | 09 |
| `save_folder_chosen` | Folder picked first time / changed | `is_icloud` | 09, 23 |
| `file_shared` | Share sheet completed | `target` (airdrop · messages · other · unknown), `format`, `screen` (result · my_files · share_card) | 09, 22, 31 |
| `file_renamed` / `file_deleted` | My files actions | `format` | 22, 39 |
| `batch_started` | Batch begins | `count`, `format` | 21 |
| `batch_completed` | Batch ends | `count`, `failed_count`, `seconds_taken` | 21, 40 |
| `merge_started` | Merge tapped | `count`, `crossfade_s`, `format` | 41 |
| `merge_completed` | Merge finished | `count`, `length_s`, `seconds_taken` | 41 → 09 |
| `background_interrupted` | iOS paused a running job | `task` (single · batch · merge), `progress_pct`, `ios_major` | 18, 21 |
| `job_resumed` | Paused job resumed | `task` | 22 |

### Ringtone

| Event | Trigger | Properties | Screen |
|-------|---------|------------|--------|
| `ringtone_created` | M4R written | `tone_type` (ringtone · alarm · text), `length_s`, `fade_in_s`, `fade_out_s` | 09b |
| `guide_opened` | Set as ringtone / Settings › How to set | `entry` (result · settings · my_files), `ios_version` | 20 |
| `guide_step_viewed` | Each guide step | `step` (1–3), `ios_version` | 20 |
| `guide_share_opened` | "Open share menu" tapped | `ios_version` | 20 |
| `guide_completed` | Step 3 "Done" | `ios_version` | 20 |
| `garageband_guide_opened` | iOS ≤ 18 link | `ios_version` | 20, 25 |

### Monetization

| Event | Trigger | Properties | Screen |
|-------|---------|------------|--------|
| `paywall_viewed` | Any paywall / sheet / card visible | `trigger` (onboarding · pro_feature · daily_limit · upsell_card · heavy_user · exit_offer · trial_reminder · winback · settings · home_chip · result · remove_ads), `variant`, `goal`, `trial_eligible` (bool), `feature` (for pro_feature) | 10–16, 09c |
| `paywall_closed` | X / Not now / swipe down | `trigger`, `seconds_on_screen` | 10–16 |
| `plan_selected` | Plan card tapped | `plan` (weekly · yearly · lifetime), `trigger` | 10 |
| `purchase_started` | CTA tapped | `plan`, `trigger`, `price`, `currency` | 10–16 |
| `trial_started` | Trial purchase succeeded | `plan`, `trigger` | 17 |
| `purchase_succeeded` | Purchase succeeded (non-trial) | `plan`, `trigger`, `price`, `currency` | 17 |
| `purchase_failed` | Error | `plan`, `trigger`, `error_code` | 17 |
| `purchase_cancelled` | User cancelled the Apple sheet | `plan`, `trigger` | 17 |
| `purchase_pending` | Ask to Buy / SCA | `plan` | 17 |
| `purchase_offline` | Purchase/restore attempted without internet | `action` (buy · restore) | 17e |
| `restore_tapped` / `restore_result` | Restore | `result` (restored · none · offline · error), `plan` | 10, 23, 17d |
| `limit_reached` | Pre-flight blocked by the free limit | `type` (daily), `used_today` | 12 |
| `pro_feature_tapped` | Pro-gated control tapped by a free user | `feature` (flac · aac · ogg · alarm · text_tone · boost · merge · batch) | 08, 06, 07, 19 |
| `free_alternative_used` | "Use MP3 instead (free)" | `feature` | 11 |
| `exit_offer_shown` / `exit_offer_accepted` / `exit_offer_expired` | P6 | `seconds_left` | 14 |
| `trial_reminder_scheduled` | Local notification scheduled (delivery can't be verified) | `hours_before_end` | – |
| `trial_reminder_opened` | Notification or P7 opened | `entry` (push · in_app) | 15 |
| `manage_subscription_tapped` | Manage / cancel link | `screen` | 15, 23 |
| `winback_shown` / `winback_accepted` | P8 | `days_since_lapse` | 16 |

### Ads and cross-promotion

| Event | Trigger | Properties | Screen |
|---|---|---|---|
| `ad_break_shown` | Our notice 42 appears | `trigger` (save · ringtone · done), `conversions_today` | 42 |
| `ad_break_continue` | Continue tapped on 42 | – | 42 |
| `ad_requested` / `ad_loaded` / `ad_failed` | Network request results | `format` (interstitial · rewarded), `provider`, `reason` (no_fill · offline · error) | – |
| `ad_shown` / `ad_closed` | Network ad displayed / closed | `format`, `provider`, `network` (mediated network name) | 43 |
| `ad_clicked` | User tapped the ad | `format`, `provider` | 43 |
| `rewarded_offered` / `rewarded_earned` | Button shown on P3 / reward callback | `rewarded_today` | 12, 43 |
| `remove_ads_tapped` | "Remove ads with Pro" / "Prefer no ads?" | `screen` | 42, 44 |
| `tracking_prompt_shown` / `tracking_result` | Our 44 / system ATT answer | `status` (authorized · denied · restricted) | 44 |
| `consent_result` | UMP form answered (EEA) | `status` | – |
| `house_card_shown` / `house_card_tapped` / `house_card_hidden` | Marberx card on Result / empty state | `app`, `screen` | 09d, 38 |
| `more_apps_opened` | Screen 45 opened | `entry` (settings · card) | 45 |
| `more_apps_tapped` | Get / View tapped | `app`, `position`, `screen` | 45, 09d, 38 |

### Self-marketing & prompts

| Event | Trigger | Properties | Screen |
|-------|---------|------------|--------|
| `rating_prompt_shown` | Pre-prompt appears | `trigger` (ringtones_2 · conversions_5), `times_shown` | 26 |
| `rating_prompt_answered` | Star tapped / Not now | `stars` (0 = not now), `routed_to` (app_store · feedback · none) | 26 |
| `feedback_sent` | Feedback mail composed | – | 26, 25 |
| `notification_prompt_shown` | Pre-prompt appears | `context` (batch · trial) | 27 |
| `milestone_reached` | Milestone sheet | `name` (first_ringtone · files_10 · files_50) | 30 |
| `share_card_opened` | Share card sheet | `entry` (milestone · result) | 31 |
| `update_prompt_shown` / `update_tapped` | Update sheet | `version` | 29 |
| `help_article_opened` | FAQ item expanded | `article` (slug) | 25 |
| `support_contacted` | Contact support | `screen` | 25, 32, 17 |

### Errors

| Event | Trigger | Properties | Screen |
|-------|---------|------------|--------|
| `error_shown` | Any error screen | `type` (conversion_failed · no_storage · icloud · drm · no_audio · save_failed · stale_folder), `code` (fixed codes from `05` §6, never native error text) | 32–36 |
| `error_recovery_action` | Primary/secondary action on an error | `type`, `action` (compatibility_mode · retry · pick_another · open_storage · save_on_iphone · share_instead · choose_folder) | 32–36 |
| `batch_retry_tapped` | Retry failed (n) | `count` | 40 |

### Account and referral (V1.3)

| Event | Trigger | Properties | Screen |
|-------|---------|------------|--------|
| `invite_entry_opened` | Invite friends tapped | `source` (settings · account), `signed_in` | 46, 47 |
| `signup_started` / `signup_completed` / `signup_failed` | Create account | `error` (email_exists · validation · network). Never send email or name | 48 |
| `login_completed` / `login_failed` | Sign in | `error` | 49 |
| `password_reset_requested` · `email_verified` · `account_deleted` | – | – | 50, 51, 52 |
| `invite_link_shared` | Share sheet completed | `channel` (if known) | 47 |
| `invite_code_redeemed` | Apply code | `source` (deep_link · manual), `result` (success · invalid · device_used · cap) | 53 |
| `referral_qualified` / `referral_rewarded` | Server webhook → app on next launch | – | – |

## Marberx-wide standard names

These names are the standard for every Marberx app (Shrink will be aligned to them): `file_picked`, `task_started` / `task_completed` / `task_failed` / `task_cancelled` (with `task` = convert · ringtone · merge · compress…), `file_saved`, `file_shared`, `paywall_viewed` / `paywall_closed`, `plan_selected`, `purchase_started` / `purchase_succeeded` / `purchase_failed` / `purchase_cancelled` / `purchase_pending`, `restore_result`, `permission_requested` / `permission_result`, `error_shown` / `error_recovery_action`, `rating_prompt_shown` / `rating_prompt_answered`, `background_interrupted`. Size and duration may be sent as buckets (`size_bucket`, `duration_bucket`) if exact values aren't needed.

## Key funnels and dashboards (build in Mixpanel)

0. **Ads health:** `ad_break_shown` → `ad_shown` (fill rate), ads per DAU, D1/D7 retention of users who saw ≥1 ad vs none, rewarded use on P3.
1. **Activation:** `onboarding_completed` → `file_picked` → `task_completed` → `file_saved` or `ringtone_created` (target ≥ 60% day 0).
2. **Ringtone success:** `ringtone_created` → `guide_opened` → `guide_step_viewed (3)` → `guide_completed`, split by `ios_major`.
3. **Paywall by trigger:** `paywall_viewed` → `purchase_started` → `trial_started` / `purchase_succeeded`, breakdown by `trigger` and `goal`.
3b. **Referral:** `invite_entry_opened` → `signup_completed` → `invite_link_shared` → `invite_code_redeemed (success)` → `referral_rewarded`.
4. **Exit offer:** `paywall_closed (onboarding)` → `exit_offer_shown` → `exit_offer_accepted`.
5. **Free-limit pressure:** `limit_reached` per DAU, and conversion within 24 h after it.
6. **Errors:** `error_shown` by `type` and `code` / `task_started` (target < 2%).
7. **Retention:** D1 / D7 / D30 by `goal` and `frequency`.
8. **Personalisation check:** trial rate by `goal`, to confirm each hero and paywall variant works.

## Implementation notes (Phase 9)

- Added trigger values: `result` ("Go unlimited" under Result) and `remove_ads` ("Remove ads with Pro" / "Prefer no ads? See Pro").
- `quality` is the preset name (standard · high · best); lossless formats and ringtones keep the preset they were made with.
- Account and referral events arrive with Phase 9b.

## QA checks (before release)

- [ ] Every event above appears in the Mixpanel **Live View** (Dev project) with the listed properties, fired exactly once per action.
- [ ] No event contains a file name, path, email or free text (search Live View for ".mp3", ".mov", "@").
- [ ] Super properties present on every event; `is_pro` / `plan` update immediately after purchase and restore.
- [ ] `task_completed.free_left` matches the counter on screen.
- [ ] RevenueCat → Mixpanel integration delivers `trial_started` / renewal events with the same `distinct_id`.
- [ ] Analytics disabled in unit tests (fake provider).

After launch, Praba connects the Mixpanel connector in Claude; Claude analyses these funnels and proposes onboarding, paywall and UI changes.
