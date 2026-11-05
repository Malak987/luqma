/// Isolated tile-provider configuration for the map picker.
///
/// Keeps URL/template, attribution and licensing notes in one place so the
/// provider can be swapped without touching presentation code.
///
/// No tile prefetching, bulk downloading or offline caching is implemented.
/// OpenStreetMap tiles are used for development/demo; they are **not**
/// guaranteed for commercial production. Review the OSM Tile Usage Policy
/// before production use: https://operations.osmfoundation.org/policies/tiles/
abstract final class TileProviderConfig {
  /// Standard OSM raster tile template.
  static const String osmUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Visible attribution required by the OSM licence (ODbL).
  static const String attribution = '© OpenStreetMap contributors';

  /// Human-readable note — shown in code/docs, not claimed as guarantee.
  static const String tileProviderNote =
      'OpenStreetMap tiles are used for development/demo. '
      'For commercial production, replace with your own tile provider and '
      'review https://operations.osmfoundation.org/policies/tiles/. '
      'Public OSM tile servers are not guaranteed for production use.';

  /// Fallback constant for reuse — kept here as documentation alias.
  /// The actual fallback coordinates live in [LocationCoordinates.sohagMapStartFallback].
  static const double sohagFallbackLatitude = 26.56;
  static const double sohagFallbackLongitude = 31.69;
}
