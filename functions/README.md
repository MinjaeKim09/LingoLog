# LingoLog Firebase Functions

This backend keeps Daily Stories local-first in the iOS app while protecting the LLM key and enforcing paid access. It also proxies Google Cloud Translation Basic v2 so provider credentials never ship in the app.

## Function

`generateDailyStory`

- Verifies the StoreKit subscription transaction JWS with Apple's App Store Server Library.
- Requires product ID `com.lingolog.dailystories.monthly`.
- Enforces one generated story per `originalTransactionId` per UTC day.
- Calls Gemini with the private `GEMINI_API_KEY` secret.
- Returns the same JSON shape used by the iOS `StoryResponse` model.

`translation`

- Requires a valid `X-Firebase-AppCheck` token issued to the configured iOS Firebase App ID.
- Applies a Firestore-backed limit of 60 requests per app per minute.
- `GET` returns `{ "languages": [{ "code": "en", "name": "English" }] }`.
- `POST` accepts `{ "text": "hello", "sourceLanguage": "en", "targetLanguage": "ko" }` and returns `{ "translatedText": "..." }`.
- Calls Google Cloud Translation Basic v2 with `format: "text"`, validates language codes against Google's supported-language list, and caches that list for 24 hours per function instance.

## Required Configuration

Set these Firebase params/secrets before deploying:

- `GEMINI_API_KEY`: Gemini API key.
- `APPLE_ROOT_CERT_BASE64`: base64-encoded Apple root certificate used by `SignedDataVerifier`.
- `BUNDLE_ID`: defaults to `mkim.LingoLog`.
- `APPLE_APP_ID`: numeric App Store app ID; required for production verification.
- `APP_STORE_ENVIRONMENT`: `Sandbox` for TestFlight/local testing, `Production` for App Store.
- `DEV_SKIP_APPLE_VERIFICATION`: defaults to `false`; set to `true` only while running local emulators before App Store subscription verification is configured.
- `GOOGLE_TRANSLATE_API_KEY`: Google Cloud Translation Basic v2 API key. Create it with `firebase functions:secrets:set GOOGLE_TRANSLATE_API_KEY`; bind it only to `translation` as implemented in `index.js`.
- `IOS_APP_ID`: the iOS Firebase App ID from `GOOGLE_APP_ID` in `LingoLog/GoogleService-Info.plist`. Both endpoints require a valid Firebase App Check token for this app ID. Firebase will prompt for this parameter when the function is deployed; use `functions/.env.local` for emulator-only values.

Before deployment, enable the Cloud Translation API in the Google Cloud project and restrict the Google API key to that API. Configure Firebase App Check for the iOS app with DeviceCheck, then register a debug token in Firebase for each simulator used during development. The iOS app sends the token itself because `translation` is a direct HTTPS function rather than a callable function.

The iOS app should point `DailyStoriesFunctionURL` at the deployed story URL and `TranslationFunctionURL` at the deployed translation URL. Release URLs must use HTTPS; the app permits HTTP only for `localhost` and `127.0.0.1` in Debug builds.

Deploy the included `firestore.rules` with `firebase deploy --only firestore:rules` (or deploy it together with functions). Direct Firestore client access is intentionally denied.

For iOS Simulator + Firebase emulator testing, use:

`http://127.0.0.1:5001/<firebase-project-id>/us-central1/generateDailyStory`

The translation emulator URL is:

`http://127.0.0.1:5001/<firebase-project-id>/us-central1/translation`

For a physical iPhone on the same Wi-Fi network, replace `127.0.0.1` with your Mac's LAN IP address.
