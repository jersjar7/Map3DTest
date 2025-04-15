import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Get API key from Flutter
    let controller = window?.rootViewController as? FlutterViewController
    let googleMapsChannel = FlutterMethodChannel(name: "com.example/google_maps", 
                                              binaryMessenger: controller!.binaryMessenger)
    
    googleMapsChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getGoogleMapsApiKey" {
        if let apiKey = call.arguments as? String {
          GMSServices.provideAPIKey(apiKey)
          result(true)
        } else {
          result(FlutterError(code: "UNAVAILABLE",
                            message: "API key not provided",
                            details: nil))
        }
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}