# LingoLog v1 release handoff

Updated September 8, 2026. Version 1.0 and its two subscription items are submitted to Apple and waiting for review. Manual release is selected.

## Completed and verified

- Apple Developer Program membership is active for team `5699GDC3LT` and renews September 7, 2027.
- App Store Connect app record created: LingoLog, bundle ID `mkim.LingoLog`, SKU `lingolog-ios`, Apple ID `6809499793`, version 1.0.
- Subscription group `Daily Stories` created with ID `22366863`. Monthly product `com.lingolog.dailystories.monthly` created with Apple ID `6809546425`, US price `$2.99`, Apple-converted pricing, all 175 storefronts plus future storefronts, English (U.S.) localization, and review notes.
- Firebase project `lingolog-eed1b` contains both HTTPS functions. App Check is registered with App Attest and team `5699GDC3LT`.
- The iOS Release provider now uses App Attest with the production entitlement, matching Firebase. Debug builds still use the debug provider.
- Translation and Gemini story sharing have separate explicit opt-ins, controls in More, and service-level guards. Reset clears those choices. Tests verify requests are rejected before network/attestation without consent.
- First-language setup has an immediate common-language list when the full network list is unavailable. Simulator verification confirmed selection and onboarding complete in that state, and the translation consent screen renders correctly. iPad Pro 13-inch launch and landscape layout were also checked in Simulator.
- iPad supports all four orientations. Unused JPEGs mislabeled as PNGs and the local StoreKit fixture are excluded from app resources.
- Privacy manifest uses Apple's valid categories for other user content, purchase history, user identifiers, and operational diagnostics. Content associated with a purchase identifier is marked linked.
- Backend verification supports sandbox transactions on a Production service only after a verified environment mismatch. Invalid signatures never cause fallback. Hosted development bypass is rejected.
- The local deployment environment has `DEV_SKIP_APPLE_VERIFICATION=false`, `APP_STORE_ENVIRONMENT=Sandbox`, and Apple app ID `6809499793`. This file is intentionally ignored by Git.
- Downloaded Apple Root CA G3 from Apple's certificate-authority website and verified its subject, dates, and acceptance by Apple's server library. Stored Firebase secret version 2.
- Deployed the tested `translation` and `generateDailyStory` functions successfully on September 7, 2026.
- Backend: 20 tests and lint pass. iOS: 18 unit/regression/consent tests pass on iPhone 17 Pro Max, iOS 26.5.
- A signed device Release archive succeeds at `/tmp/LingoLog-signed.xcarchive`. App Store export succeeds at `/tmp/LingoLog-AppStore/LingoLog.ipa`; signature inspection confirms Apple Distribution team `5699GDC3LT`, bundle `mkim.LingoLog`, and production App Attest entitlement.
- App Store validation initially found a missing 152×152 iPad icon and invalid bundle package type. Both packaging issues were corrected, all icon assets were converted to real PNG files, and the corrected `/tmp/LingoLog-signed-v2.xcarchive` passed every App Store validation check.
- LingoLog 1.0 build 1 was uploaded successfully to App Store Connect. Its export-compliance declaration is complete and it is Ready to Submit.
- Build 2 includes `ITSAppUsesNonExemptEncryption=false` and the production privacy-policy link. Its signed archive succeeded at `/tmp/LingoLog-build2.xcarchive`, it was uploaded successfully, reached Ready to Submit, and is selected and saved on App Store version 1.0.
- App Store copy and screenshot shot list are in `APP_STORE_METADATA.md`.
- Four final iPhone screenshots with fictional Korean vocabulary are in `app-store-screenshots/upload-6.5` at App Store-ready 1284×2778 resolution, including the `$2.99/month` paywall. Native 1320×2868 captures are retained in the parent folder.
- The public support, privacy, and terms pages are live through GitHub Pages. Support email `kim.minjae@nyu.edu` was confirmed by the owner.
- App Store Connect uses Education as the primary category and a 4+ age rating. The privacy label is published with user content, user/device identifiers, and purchase history linked to the user; operational diagnostics are not linked; no data is used for tracking.
- The App Store Support URL and Privacy Policy URL are populated with the live GitHub Pages site.
- The app itself is priced Free and is available in all 175 App Store countries and regions on release. The optional Daily Stories subscription remains US `$2.99/month` with Apple-converted storefront pricing.
- The three-item package was submitted to Apple on September 8, 2026 at 5:48 PM: iOS app version 1.0 build 2, the `Daily Stories` subscription group, and the `Daily Stories Monthly` subscription. Submission ID: `9333e820-85cf-46df-87f4-be5c225952a6`. All three items currently show `Waiting for Review`.
- A clean 13-inch iPad screenshot was captured at the required 2064×2752 resolution, saved as `app-store-screenshots/05-ipad-home.png`, and uploaded to version 1.0.

## Support site

The simple support, privacy, and terms pages are stored directly in `docs/` and published from the `ui-overhaul` branch's `/docs` folder at https://minjaekim09.github.io/LingoLog/. The app and App Store Connect link to the live privacy policy at `privacy.html`.

## Requires owner / App Store completion

- Final subscription pricing is approved at US $2.99/month; the local StoreKit fixture matches.
- Confirm paid development team and distribution signing in Xcode. Enable App Attest on the registered App ID if required.
- Paid Apps Agreement accepted; its status is `Pending User Info`. The U.S. W-9 is now Active. Add a bank account and complete the EU Digital Services Act trader-status declaration personally.
- The subscription review screenshot and four iPhone App Store screenshots are uploaded.
- Record the numeric App Store app ID in `APPLE_APP_ID`; set `APP_STORE_ENVIRONMENT=Production` when ready to handle real purchases. The code then also accepts verified sandbox review/TestFlight purchases.
- Verify provider key restrictions, Gemini key billing/data-processing configuration, and live Firestore rules. Their deployed values have not been audited.
- Register an authorized simulator debug token if simulator online testing is needed; verify production App Attest on a physical device.

## Remaining release gates

- Verify successful translation/story requests, invalid attestation, real sandbox purchase, restore, expiry/cancellation, and quota recovery against the deployed backend.
- Test physical iPhone and iPad, iPad landscape, VoiceOver, larger text, dark mode, notifications, export, reset, offline errors, and upgrade behavior.
- Complete any remaining Mac/Apple Vision Pro availability and accessibility declarations.
- Complete any remaining desired TestFlight testing.
- Monitor App Store Connect and the support email for App Review questions or a decision. Manual release is selected, so an approval will still require releasing version 1.0 from App Store Connect.

## Known limits

The backend still has no automatic expiry for story/quota records; the drafted policy discloses this instead of promising a retention limit that does not exist. Data-reset in the app is local only. Existing Swift concurrency warnings remain warnings under the project's current Swift language mode. Device signing, live purchases, and production App Attest remain unverified.
