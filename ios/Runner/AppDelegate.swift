import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK for iOS — API key from untracked local configuration.
    // Never hardcode a real key in source. The key must be injected via
    // ios/Runner/GoogleMaps-Info.plist (or environment) and restricted in
    // Google Cloud Console → APIs & Services → Credentials:
    //   • Application restriction → iOS apps → Bundle ID: com.example.luqmaApp
    //   • API restriction → Maps SDK for iOS (and Geocoding if used)
    // See ios/Runner/README_MAPS.md for setup. If the key is missing,
    // the map will not load; the Dart layer shows a localized error.
    if let apiKey = GoogleMapsAPIKeyProvider.apiKey, !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    } else {
      // No key — map will show Google's error; Dart UI handles gracefully.
      // Never log the key value.
      debugPrint("[Maps] Google Maps iOS API key not configured — map disabled")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
