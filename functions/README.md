# LingoLog Firebase Functions

This backend keeps Daily Stories local-first in the iOS app while protecting the LLM key and enforcing paid access.

## Function

`generateDailyStory`

- Verifies the StoreKit subscription transaction JWS with Apple's App Store Server Library.
- Requires product ID `com.lingolog.dailystories.monthly`.
- Enforces one generated story per `originalTransactionId` per UTC day.
- Calls Gemini with the private `GEMINI_API_KEY` secret.
- Returns the same JSON shape used by the iOS `StoryResponse` model.

## Required Configuration

Set these Firebase params/secrets before deploying:

- `GEMINI_API_KEY`: Gemini API key.
- `APPLE_ROOT_CERT_BASE64`: base64-encoded Apple root certificate used by `SignedDataVerifier`.
- `BUNDLE_ID`: defaults to `mkim.LingoLog`.
- `APPLE_APP_ID`: numeric App Store app ID; required for production verification.
- `APP_STORE_ENVIRONMENT`: `Sandbox` for TestFlight/local testing, `Production` for App Store.
- `DEV_SKIP_APPLE_VERIFICATION`: defaults to `false`; set to `true` only while running local emulators before App Store subscription verification is configured.

The iOS app should point `DailyStoriesFunctionURL` at the deployed HTTPS function URL.

For iOS Simulator + Firebase emulator testing, use:

`http://127.0.0.1:5001/<firebase-project-id>/us-central1/generateDailyStory`

For a physical iPhone on the same Wi-Fi network, replace `127.0.0.1` with your Mac's LAN IP address.
