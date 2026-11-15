/// An in-memory consent capability scoped to one map-picker session.
///
/// Keep the opaque [sessionToken] only in memory. Do not serialize or persist
/// this object. A token from a previous session cannot authorize a later one.
final class ReverseGeocodingConsent {
  const ReverseGeocodingConsent._(this._sessionToken);

  final Object _sessionToken;

  /// Creates consent only after the user has explicitly agreed in this session.
  factory ReverseGeocodingConsent.grantedForSession({
    required Object sessionToken,
  }) {
    return ReverseGeocodingConsent._(sessionToken);
  }

  bool isValidForSession(Object sessionToken) =>
      identical(_sessionToken, sessionToken);
}
