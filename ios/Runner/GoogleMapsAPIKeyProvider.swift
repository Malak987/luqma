import Foundation

/// Provides the Google Maps iOS API key from an untracked local source.
///
/// Resolution priority:
/// 1. `ios/Runner/GoogleMaps-Info.plist` (untracked, gitignored) with key `GOOGLE_MAPS_IOS_API_KEY`
///    — create this file locally per `ios/Runner/README_MAPS.md`.
/// 2. `Info.plist` → `GOOGLE_MAPS_IOS_API_KEY` (if you prefer to inject via Xcode build phase).
/// 3. Environment variable via `ProcessInfo` (for CI).
///
/// Never commit real keys. All sources are local/CI-only.
enum GoogleMapsAPIKeyProvider {
  /// Returns the API key if configured locally, otherwise nil.
  static var apiKey: String? {
    // 1. Dedicated local plist (preferred — untracked).
    if let plistPath = Bundle.main.path(forResource: "GoogleMaps-Info", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
       let key = dict["GOOGLE_MAPS_IOS_API_KEY"] as? String,
       !key.trimmingCharacters(in: .whitespaces).isEmpty,
       !key.contains("YOUR_") {
      return key
    }

    // 2. Info.plist injection (alternative — if build script injects it).
    if let dict = Bundle.main.infoDictionary,
       let key = dict["GOOGLE_MAPS_IOS_API_KEY"] as? String,
       !key.trimmingCharacters(in: .whitespaces).isEmpty,
       !key.contains("YOUR_") {
      return key
    }

    // 3. Environment (CI).
    if let key = ProcessInfo.processInfo.environment["GOOGLE_MAPS_IOS_API_KEY"],
       !key.trimmingCharacters(in: .whitespaces).isEmpty {
      return key
    }

    return nil
  }
}
