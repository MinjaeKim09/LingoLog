# LingoLog App Review response — 1.0 (build 2)

Status: response prepared, not sent. The App Store Connect submission is unchanged.

This is the canonical response. After the physical-device evidence is added, paste the same finalized text into both the App Review reply and App Review Information → Notes.

## 1. Screen recording and review access

Recording status: **NOT YET RECORDED**. Do not send this response until the placeholders below are replaced with the actual playable recording and test results.

- Recording attachment or URL: `[ADD PLAYABLE RECORDING]`
- Device model: `[ADD PHYSICAL IPHONE MODEL]`
- Public OS version: `[ADD IOS VERSION]`
- App version/build: LingoLog 1.0 (build 2)
- Test date: `[ADD TEST DATE]`

The recording will begin by launching the submitted TestFlight build and will show the normal flow:

1. Create a local profile and a Korean learning space with English meanings.
2. Read and accept the translation disclosure, then save three fictional vocabulary entries.
3. Open saved words, vocabulary practice, and study progress.
4. Open Stories, read the sharing disclosure, and choose “Unlock stories.”
5. Show the complete Daily Stories paywall, including the subscription title, monthly duration, localized price, renewal text, Restore Purchases, Terms, and Privacy links. Open both legal links.
6. Complete a TestFlight sandbox purchase, generate a story, and complete its comprehension quiz.
7. Create another language space, then demonstrate subscription restoration and management from More.

LingoLog has no account registration, login, account deletion, public feed, user-to-user interaction, user-generated public content, reporting flow, or blocking flow. No credentials or sample files are required.

## 2. Purpose and target audience

LingoLog is a personal language-learning app for people who want to collect vocabulary encountered in daily life, practice it with spaced repetition, and read personalized stories using words they have saved. It helps learners keep a private vocabulary collection, review words at the right time, and reinforce comprehension through quizzes.

## 3. Setup and access

The user creates a local profile and a learning language space. For the review walkthrough, create a Korean space with English meanings, allow online translation when prompted, and save at least three fictional words. The main features are available from the Today, Words, Practice, and Stories areas. More contains online-feature consent controls, Restore Purchases, and Manage Subscription.

No LingoLog account, login credentials, demo account, or sample files are required. The profile, vocabulary, progress, language spaces, and saved stories are initially stored on the device. Reset All Data is a local reset; it is not described as deletion of server-side story or quota records.

## 4. External services

- **Google Cloud Translation:** receives text and the selected source and target languages through a Firebase HTTPS function when the user allows online translation. It provides translated meanings and the supported-language list.
- **Google Gemini:** receives selected vocabulary, meanings, and the learning language through a Firebase HTTPS function when the user allows AI story sharing. It generates the personalized story and comprehension questions.
- **Firebase Cloud Functions:** provides the server-side translation and Daily Stories endpoints, validates requests, and coordinates provider calls.
- **Firebase Firestore:** stores completed story results, the vocabulary used, the language, the UTC date, and a persistent Apple purchase transaction identifier. This supports story recovery after an interrupted request and enforces the one-story-per-subscription-per-UTC-day allowance.
- **Firebase App Check with Apple App Attest:** helps verify that online requests come from the signed LingoLog app. Invalid or missing attestation is rejected.
- **Apple StoreKit / In-App Purchase:** loads the subscription, presents the purchase flow, restores purchases, opens subscription management, and provides signed transaction information. The backend verifies the signed transaction before enabling Daily Stories.

## 5. Regional behavior

The current app configuration has no app-defined regional feature or content variations. The core experience is the same where the app and its services are available. Subscription prices and currencies are localized by the Apple storefront, and translation/story features depend on an internet connection and provider availability. We have not independently verified availability in every country or region.

## 6. Regulated services and protected material

LingoLog is a language-learning app and does not operate in a regulated industry. The shipped app bundle contains app UI and app-icon assets, not a catalog of third-party books, articles, music, photos, or other protected material. Final asset ownership/provenance must be confirmed by the account holder before sending this response; no additional regulated-service authorization is expected once that confirmation is complete.

## 7. In-App Purchase

LingoLog has one optional auto-renewing monthly subscription: **Daily Stories** (`com.lingolog.dailystories.monthly`). It unlocks personalized stories made from saved vocabulary, a comprehension quiz after each story, and additional language spaces. The allowance is one generated story per subscription per UTC day, shared across learning languages; retrying an interrupted request in the same language recovers the existing result.

To reach the purchase flow, open **Stories → Unlock stories**. The paywall displays the subscription title, monthly duration, localized price, renewal language, Restore Purchases, Terms, and Privacy links. Restore Purchases and Manage Subscription are also available in **More**.

## QA status to finalize before sending

Automated checks completed locally:

- iOS: 18 unit/regression/consent tests passed with `xcodebuild test` on the iPhone 17 Pro Max, iOS 26.5 simulator.
- Backend: 20 tests passed with `npm test`.
- Backend lint: `npm run lint` passed.

Partial physical-device smoke checks completed on September 10, 2026:

- Device: iPhone 13 Pro Max, iOS 27.0.
- LingoLog launched and showed the local profile, Korean learning space, More controls, and an active Daily Stories entitlement.
- The Apple sandbox subscription-management screen opened and showed LingoLog Daily Stories at `$2.99 per month` with a renewal date.
- The Privacy and Terms links opened successfully in Chrome on the device.
- A fictional `hello` entry translated successfully through the live Google Cloud Translation path, and the unsaved test entry was canceled.
- An existing Daily Story opened and its comprehension quiz completed with `4 of 4 correct`.
- Restore Purchases reached the Apple Account password prompt; the prompt was canceled without entering credentials. Restore therefore remains unverified.

Still unverified and required before sending:

- Playable physical-iPhone recording of TestFlight build 2.
- Live sandbox purchase, paid story generation, restore, cancellation/expiry, and quota recovery. (Existing entitlement, management, story reading, and quiz completion were smoke-checked above.)
- Production App Attest on a physical device and the deployed backend's live configuration.
- Physical iPad testing, including landscape, accessibility, offline/error, reset, and larger-text checks.
- Current Paid Apps Agreement, bank, and EU Digital Services Act trader-status requirements.
- Owner confirmation of bundled-asset provenance.

The deployed environment must be confirmed as `APP_STORE_ENVIRONMENT=Production` with `DEV_SKIP_APPLE_VERIFICATION=false` before public release. The uncommitted `functions/index.js` Gemini model/schema change is not deployment evidence and must not be represented as live until deployed and tested.
