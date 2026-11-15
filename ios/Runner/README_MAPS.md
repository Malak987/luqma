# Google Maps SDK — iOS Setup (Luqma)

This document explains how to configure the **Google Maps SDK for iOS** locally without committing secrets.

## Prerequisites

1. **Google Cloud project** with billing enabled.
2. Enable **Maps SDK for iOS** in [Cloud Console → APIs](https://console.cloud.google.com/apis/library/maps-sdk-ios.googleapis.com).
3. Enable **Geocoding API** only if you plan to use server-side reverse geocoding (currently consent-gated in app).

## Create a restricted API key

1. Console → **APIs & Services → Credentials → Create credentials → API key**.
2. Restrict the key:
   - **Application restriction** → **iOS apps**
     - Bundle ID: `com.example.luqmaApp` (from `ios/Runner.xcodeproj` → `PRODUCT_BUNDLE_IDENTIFIER`)
     - For tests: `com.example.luqmaApp.RunnerTests` is also allowed if needed.
   - **API restriction** → **Restrict key** → Select `Maps SDK for iOS` (and `Geocoding API` if used).
3. Copy the key value.

## Inject the key locally (do NOT commit)

Choose one of:

### Option A — Local plist (recommended)

1. Copy `ios/Runner/GoogleMaps-Info.plist.example` → `ios/Runner/GoogleMaps-Info.plist` (this file is gitignored).
2. Replace `YOUR_IOS_GOOGLE_MAPS_KEY_HERE` with your real key.
3. `ios/Runner/GoogleMaps-Info.plist` is read at launch by `GoogleMapsAPIKeyProvider.swift`; if missing, the app shows a localized map-unavailable message.

### Option B — Xcode build-phase injection (CI)

Add a build step that injects `GOOGLE_MAPS_IOS_API_KEY` into `Info.plist` or environment:

```bash
/usr/libexec/PlistBuddy -c "Add :GOOGLE_MAPS_IOS_API_KEY string $GOOGLE_MAPS_IOS_API_KEY" ios/Runner/Info.plist
```

### Option C — Environment variable (CI)

Set `GOOGLE_MAPS_IOS_API_KEY` in your CI environment; `GoogleMapsAPIKeyProvider` reads `ProcessInfo.processInfo.environment`.

## Native initialization

`ios/Runner/AppDelegate.swift` already calls:

```swift
if let apiKey = GoogleMapsAPIKeyProvider.apiKey { GMSServices.provideAPIKey(apiKey) }
```

No `Info.plist` `io.flutter.embedded_views_preview` flag is needed for current SDK.

## Verification

- Run `flutter run` → open map picker → map should display Luqma Ivory (light) or Charcoal (dark) style.
- If key is missing/invalid, the SDK shows a gray tile with Google's error; the app preserves camera/selection and shows a localized explanation.
- Never log the key value — the app only logs `key not configured`.

## Troubleshooting

- **“API not enabled”**: Enable Maps SDK for iOS in Cloud Console.
- **“This IP/bundle not authorized”**: Check bundle ID restriction exactly matches `com.example.luqmaApp`.
- **Black map**: Ensure `GoogleMaps` import compiles (`pod install` after adding `google_maps_flutter`).
