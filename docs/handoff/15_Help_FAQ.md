# 15 · Help & FAQ content

Final text for the in-app **Help & FAQ** screen (25) and the support web page (marberx.com/tunely/help). Keep app and web identical.

- **In the app:** the first 7 questions (marked ★) are listed on screen 25, in this order. All questions are searchable from the search field.
- **Tone:** short, friendly, plain English. Every answer gives the next step.
- **Strings:** put each Q/A in the ARB file (`faq_<slug>_q` / `faq_<slug>_a`). The `slug` is used in the `help_article_opened` event.
- **Prices:** never write them in answers. Say "the price shown in the app" because prices come from the App Store.

---

## Getting started

**★ Why do I see ads?** `ads`
Ads keep Tunely free. You only see a short ad between tasks, after your file is already saved, never while converting. Tunely Pro removes all ads.

**★ How do I set a ringtone?** `set-ringtone`
After you make a ringtone, tap **Set as ringtone** and follow the 3 steps.
- **On iOS 26:** tap **Share**, then **Use as Ringtone**. Then pick it in iPhone **Settings › Sounds & Haptics › Ringtone** (it's at the top).
- **On iOS 18 or older:** we guide you through the free GarageBand app (Help › "Set a ringtone with GarageBand").

**★ Why can't I convert Apple Music songs?** `drm`
Songs from Apple Music and other streaming services are copy-protected (DRM), so no app can convert them. Your own videos, voice memos and DRM-free music files work fine.

**★ Will quality drop?** `quality`
Choose **High (256 kbps)** or **Best (320 kbps)** and most people can't hear a difference. Before you convert, Tunely shows the estimated file size. If your file is already lower quality, a higher setting won't make it better.

**★ Where are my files saved?** `where-saved`
Every file you make appears in **My files** inside Tunely. When you tap **Save to Files**, Tunely also saves a copy to your **Tunely folder** in Files (iCloud Drive › Tunely by default; you choose it the first time). Copies in that folder stay even if you delete the app. Files only inside Tunely are removed if you delete the app.

**★ How do free conversions work?** `free-conversions`
You get 3 full-quality conversions every day, ringtones included. They reset at midnight. Failed or cancelled conversions never count. When you run out, you can watch a short ad for 1 more (up to 2 a day), wait until tomorrow, or go Pro for unlimited.

**★ How do I cancel my subscription?** `cancel`
Open Tunely **Settings › Manage subscription**, or iPhone **Settings › [your name] › Subscriptions › Tunely Pro**. If you allow notifications, we remind you a day before any free trial ends. Cancel at least 24 hours before the renewal date to avoid the next charge.

## Converting

**What can I convert?** `what-can-i-convert`
Videos from Photos or Files (MOV, MP4, M4V) and audio files (MP3, M4A, AAC, WAV, AIFF, CAF, FLAC). You can save as MP3, M4A or WAV for free, and as FLAC, AAC or OGG with Pro.

**How do I turn a video into an MP3?** `video-to-mp3`
On Home, tap **Video to MP3** (or the big button), pick a video, check the format and quality, then tap **Convert to MP3**. When it's done, tap **Save to Files** or **Share**.

**Does Tunely upload my files?** `privacy`
No. Everything is converted on your iPhone. Your videos and songs are never uploaded, and ads never see your files.

**Do I need internet?** `offline`
Converting works without internet. You need internet to buy or restore Pro, to download videos stored only in iCloud, and to load ads.

**Why does it say the video has no sound?** `no-audio`
That video has no audio track (some screen recordings and muted clips), so there's nothing to convert. Try another video.

**It says "still in iCloud". What do I do?** `icloud`
The video isn't fully on your iPhone yet. Connect to Wi-Fi (or turn off Low Data Mode) and tap **Try again**, or open it once in Photos so it downloads.

**Converting failed. What now?** `conversion-failed`
Tap **Try compatibility mode**. It works for almost every video. Your original file is never changed. If it still fails, tap **Contact support**; the error code is added for us automatically.

**It says I need more space.** `storage`
Converting needs a little room for a temporary copy. Empty **Recently Deleted** in Photos, remove old files in **My files**, or choose **Standard** quality, then tap **Check again**.

**Can I keep converting when I leave the app?** `background`
On iOS 26, yes: it keeps going in the background. On older iOS, it may pause until you come back, and then it continues. A paused job never uses a free conversion.

## Ringtones

**How long can a ringtone be?** `ringtone-length`
Up to 30 seconds. Drag the handles to pick the part you like; fade in and out are added for you (you can change them).

**What are alarm and text tones?** `alarm-text-tones`
They're short sounds for alarms and messages. Making them is part of Tunely Pro. Ringtones are free.

**I can't find my ringtone in Settings.** `ringtone-missing`
Make sure you finished the last step of the guide. On iOS 26 it appears at the top of **Settings › Sounds & Haptics › Ringtone**. On older iOS, check that you exported it from GarageBand as a ringtone.

## Editing

**How do I cut or fade a song?** `trim-fade`
On the Convert screen, tap **Trim & fade**. Drag the handles or use −1 s / +1 s, set fade in and out, then tap **Done**.

**How do I join songs into one?** `merge`
Tap **Merge audio** on Home (Pro), pick 2 to 10 files, drag to change the order, choose a crossfade, then tap **Merge**. Your original files are not changed.

**Can I convert many files at once?** `batch`
Yes, with Pro: pick up to 50 files and tap **Continue**. Finished files are saved as they complete; if one fails, you can retry just that one.

**What is volume boost?** `volume-boost`
Pro can make quiet audio up to +6 dB louder without distortion.

## Tunely Pro & purchases

**What do I get with Tunely Pro?** `pro`
Unlimited conversions and ringtones, no ads, FLAC/AAC/OGG formats, batch (up to 50 files), merge audio, volume boost, and alarm and text tones.

**How does the free trial work?** `trial`
If you're eligible, Yearly starts with 3 days free. You won't be charged until the trial ends, and you can cancel anytime before. If you've had a trial before, the app shows the regular price instead.

**I bought Pro but it's not showing.** `restore`
Tap **Settings › Restore purchases**. Make sure you're signed in with the same Apple Account you used to buy. If it says "No purchases found", check the account in iPhone Settings and try again.

**Can I get a refund?** `refund`
Refunds are handled by Apple. Go to reportaproblem.apple.com and choose Tunely Pro.

**Does Pro work on my other devices?** `devices`
Yes, on any iPhone signed in with the same Apple Account. Tap **Restore purchases** on the new device.

## Your files

**Does deleting a file in Tunely delete my original?** `delete`
No. Deleting removes the file from **My files** only. The original video in Photos and any copies you saved to your Tunely folder in Files are kept.

**Can I rename files?** `rename`
Yes. In **My files**, tap **⋯** next to a file, then **Rename**.

**My Tunely folder can't be found.** `folder-missing`
The folder was moved, renamed or deleted. Tap **Choose folder again** and pick a folder (iCloud Drive › Tunely is a good choice).

## Account & invites

**Do I need an account?** `account`
No. Everything works without one. An account is only for invite rewards.

**How do invite rewards work?** `invites`
Go to **Settings › Invite friends**, create a free account and share your link. Your friend gets a week of Pro right away (no account needed). You get a week when they make their first file.

**I have an invite code. Where do I enter it?** `invite-code`
**Settings › Have an invite code?** If you opened your friend's link, the code is filled in for you.

**How do I delete my account?** `delete-account`
**Settings › Account › Delete account.** Your files and your Pro subscription are not affected.

## Privacy & ads

**Why does iPhone ask about tracking?** `tracking`
Ad networks can show more relevant ads if you allow it. Either answer is fine, and Tunely works the same. You can change it anytime in iPhone **Settings › Privacy & Security › Tracking**.

**How do I remove ads?** `remove-ads`
Get Tunely Pro. All ads disappear right away.

**What are the app suggestions from Marberx?** `more-apps`
Marberx makes Tunely and a few other small apps (like Shrink: Video Compressor). We sometimes show one that fits what you're doing. You can hide a suggestion with ×, and nobody is paid when you install.

---

**Contact support:** opens Mail to support@marberx.com with the app version, iOS version and (if any) the error code. Never attach the user's files automatically.
