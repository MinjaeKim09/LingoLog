# LingoLog 1.0 — App Store submission copy

Prepared September 7, 2026. Save these fields after membership activation.

| Field | Value |
| --- | --- |
| Name | LingoLog |
| Subtitle | Words from your world |
| Primary language | English (U.S.) |
| Bundle ID | mkim.LingoLog |
| SKU | lingolog-ios |
| Version / build | 1.0 / 1 (increment build for subsequent uploads) |
| Suggested primary category | Education |
| Suggested secondary category | Reference |
| Base app price | Free |
| Subscription product ID | com.lingolog.dailystories.monthly |
| Subscription group / display name | Daily Stories |
| Subscription duration | 1 month |
| Subscription description | Daily AI stories using your saved words, plus additional language spaces. |
| Subscription price | US $2.99/month (owner approved) |
| Release | Manual release after approval |

## Description

Keep the words you meet. Practice them until they stick.

LingoLog helps you build a personal vocabulary collection from everyday reading, conversations, shows, and podcasts. Save a word, find its meaning, and add a memory cue to remember where you found it.

• Capture words in your learning language or translate from a language you already know.
• Review your collection with spaced repetition and focused vocabulary quizzes.
• Track your study streak and see which words are ready for another review.
• Keep your learning data on your device and export your vocabulary.

With an optional Daily Stories subscription, turn selected words into an AI-generated reading with comprehension questions and organize additional language spaces. Generate one story per subscription per UTC day, shared across your learning languages. AI-generated content may contain errors.

Online translation uses Google Cloud Translation. Daily Stories uses Google Gemini. These features ask for your permission before sharing your words. No LingoLog account is required.

Daily Stories is an auto-renewing monthly subscription. The price is shown before purchase. Manage or cancel your subscription in your Apple account settings.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

[Add the published Privacy Policy URL before submission.]

## Keywords

vocabulary,language,spaced repetition,translation,study,words,reading,quiz,immersion

## Review notes

LingoLog uses a local profile and does not require account creation or a demo login.

1. Create a language space, such as Korean with English meanings.
2. Open Add Word, allow online translation, and save at least three words.
3. Use Practice to review saved words.
4. Open Stories, read and allow the AI sharing disclosure, and open the Daily Stories paywall.
5. Test the monthly subscription in the Apple review sandbox. Restore Purchases and Manage Subscription are available in More.
6. Create a story and complete its comprehension quiz. The daily limit is one story per subscription per UTC day, across languages; retrying the same day/language recovers the existing result.

Keep the backend running during review. Supply reviewer contact information in App Store Connect. Attach the first subscription to the app version submission.

## Screenshot shot list

Capture actual final-build UI using fictional example vocabulary. Do not show developer overrides, debug banners, credentials, or unimplemented functionality.

1. Today — collection, streak, next review.
2. Add Word — useful translated word and memory cue.
3. Words — a populated language collection.
4. Practice — vocabulary question.
5. Stories — generated reading with vocabulary in context.
6. Optional: comprehension quiz or language spaces.

Current target supports iPhone and iPad. Capture the required device-size sets shown by App Store Connect, including iPad. Check portrait/landscape, large text, VoiceOver, and dark appearance before selecting final screenshots.

## Questionnaire preparation

- Answer age rating from actual content and AI behavior; do not guess all answers as No.
- Review encryption/export compliance against the shipped app and SDKs. HTTPS alone does not justify an unreviewed declaration.
- Review distribution countries, EU trader status, and Mac/Apple Vision Pro compatibility availability.
- Privacy labels must cover the backend and third-party SDKs, not only local Core Data. Story content is stored with a persistent purchase identifier, so do not describe all collected content as unlinked.
