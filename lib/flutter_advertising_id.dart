import 'flutter_advertising_id_platform_interface.dart';

/// A class that provides methods to interact with the advertising ID and
/// limit ad tracking settings of the platform.
class AdvertisingId {
  /// Retrieves the advertising ID of the device.
  ///
  /// If [requestTrackingAuthorization] is set to `true`, it will request
  /// tracking authorization from the user before retrieving the ID.
  ///
  /// Returns a `Future` that resolves to the advertising ID as a `String?`.
  /// On HarmonyOS, missing permission or an unavailable ID resolves to `null`.
  /// Native service failures may throw a platform exception.
  Future<String?> getAdvertisingId([
    bool requestTrackingAuthorization = false,
  ]) async {
    return FlutterAdvertisingIdPlatform.instance.getAdvertisingId(
      requestTrackingAuthorization,
    );
  }

  /// Checks whether the "Limit Ad Tracking" setting is enabled on the device.
  /// On HarmonyOS, reports whether app tracking permission is not granted;
  /// querying this value does not request permission.
  ///
  /// Returns a `Future` that resolves to a `bool?` indicating the status:
  /// - `true`: Limit Ad Tracking is enabled.
  /// - `false`: Limit Ad Tracking is disabled.
  /// - `null`: Unable to determine the status.
  Future<bool?> get limitAdTrackingEnabled async {
    return await FlutterAdvertisingIdPlatform.instance.limitAdTrackingEnabled;
  }

  /// Retrieves the current tracking authorization status of the device. This will always
  /// return `AdTrackingAuthorizationStatus.authorized` on Android.
  /// HarmonyOS returns authorized or denied based on app tracking permission,
  /// without requesting permission or distinguishing a first-time denial.
  ///
  /// Returns a `Future` that resolves to a `AdTrackingAuthorizationStatus` enum value:
  /// - `AdTrackingAuthorizationStatus.notDetermined`: The user has not yet made a choice regarding tracking.
  /// - `AdTrackingAuthorizationStatus.restricted`: The user has restricted tracking.
  /// - `AdTrackingAuthorizationStatus.denied`: The user has denied tracking.
  /// - `AdTrackingAuthorizationStatus.authorized`: The user has authorized tracking.
  Future<AdTrackingAuthorizationStatus> get authorizationStatus async {
    return await FlutterAdvertisingIdPlatform.instance.authorizationStatus;
  }
}

/// The possible tracking authorization statuses for the device.
enum AdTrackingAuthorizationStatus {
  /// The user has not yet made a choice regarding tracking.
  notDetermined,

  /// The user has restricted tracking.
  restricted,

  /// The user has denied tracking.
  denied,

  /// The user has authorized tracking.
  authorized,
}
