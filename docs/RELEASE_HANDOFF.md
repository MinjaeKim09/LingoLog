# v1 release handoff

The repository is ready for a configured production build. Complete these external steps before uploading to App Store Connect.

## Firebase and provider configuration

1. Enable Firebase App Check for the iOS app using DeviceCheck, and register a debug token for each development simulator.
2. Set Firebase Functions secrets: `GEMINI_API_KEY`, `GOOGLE_TRANSLATE_API_KEY`, and `APPLE_ROOT_CERT_BASE64`.
3. Set Firebase parameters: `IOS_APP_ID` (the `GOOGLE_APP_ID` in `GoogleService-Info.plist`), `BUNDLE_ID`, `APPLE_APP_ID`, and `APP_STORE_ENVIRONMENT=Production`. Keep `DEV_SKIP_APPLE_VERIFICATION=false`.
4. Restrict the client-visible Firebase API key to bundle ID `mkim.LingoLog` and only required Firebase APIs. Restrict the Translation key to Cloud Translation.
5. Deploy both functions and Firestore rules. Enter their HTTPS URLs in `LingoLog/AppConfig.plist`.

## App Store setup

1. Create `com.lingolog.dailystories.monthly` in App Store Connect with its monthly price, localization, review screenshot, tax/banking details, and subscription group.
2. Publish a real Privacy Policy, Terms of Service, and Support URL. Enter the first two in `AppConfig.plist` and all required URLs in App Store Connect.
3. Complete the App Privacy questionnaire: vocabulary, translations, contexts, and generated story requests are User Content sent to the app's service providers for app functionality; the app does not track users.
4. Verify purchases, restores, cancellations, App Check, and production transaction verification through TestFlight before release.

## Final QA

- Test a clean install, an upgrade, reset-all-data, export, notifications, offline/error states, Dynamic Type, VoiceOver, and dark mode on physical devices.
- Archive with a distribution signing profile, validate the archive, and use TestFlight before submission.
- `npm audit` currently reports eight moderate transitive advisories. The current compatible Firebase Functions 7/Admin 13 pair has no non-breaking fix; revisit when Functions supports Firebase Admin 14.
