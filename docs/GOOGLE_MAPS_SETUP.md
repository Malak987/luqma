# Google Maps SDK — Luqma Setup

Official SDK: [`google_maps_flutter ^2.19.0`](https://pub.dev/packages/google_maps_flutter) (min Dart 3.13, Flutter 3.27+; project is Dart >=3.6, Flutter >=3.27).

## APIs to enable (Google Cloud Console)

- **Maps SDK for Android** (Android maps)
- **Maps SDK for iOS** (iOS maps)
- **Geocoding API** *optional* — only if you later enable server reverse-geocoding (currently consent-gated)

## Android

### 1. Create key
Console → Credentials → Create API key → Restrict:
- **Android apps** → Package: `com.example.luqma_app` (from `android/app/build.gradle.kts` `applicationId`)
- Add SHA-1 fingerprints:
  - Debug: `cd android && ./gradlew signingReport` or `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`
  - Release: `keytool -list -v -keystore /path/to/release.jks`
- API restriction → `Maps SDK for Android`

### 2. Inject locally
1. Copy `android/local.properties.example` → `android/local.properties` (gitignored).
2. Set `GOOGLE_MAPS_API_KEY=YOUR_REAL_KEY`.
3. `android/app/build.gradle.kts` loads this into `manifestPlaceholders["GOOGLE_MAPS_API_KEY"]`.
4. `AndroidManifest.xml` uses `<meta-data android:name="com.google.android.geo.API_KEY" android:value="${GOOGLE_MAPS_API_KEY}"/>`.

**Dart `--dart-define` does NOT configure Android** — you must use `local.properties`.

## iOS

See `ios/Runner/README_MAPS.md`.

Summary: Copy `ios/Runner/GoogleMaps-Info.plist.example` → `ios/Runner/GoogleMaps-Info.plist` (gitignored), insert key with bundle restriction `com.example.luqmaApp`.

**Dart `--dart-define` does NOT configure iOS** — use the local plist.

## Map styling

- No Cloud Map ID needed.
- Styles are local JSON in `lib/core/map/google_maps_config.dart`: `lightStyleJson` (Luqma Ivory, `#F6F1E7`/`#FAF7F0`) and `darkStyleJson` (Minimal Charcoal, `#1A1A1A`).
- Applied via `GoogleMapController.setMapStyle(json)` on `onMapCreated` and on theme changes.

## Branding

Burgundy `#7B1E28` is preserved for marker & recenter. No Teal.

## Troubleshooting

- Gray map / “API key not found”: Check `local.properties` / `GoogleMaps-Info.plist` exist locally and keys are restricted correctly.
- `minSdk` error: Project now requires `minSdk 24` (Maps SDK). Update device/emulator.
