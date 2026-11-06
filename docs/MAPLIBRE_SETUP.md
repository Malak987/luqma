# Luqma Map System — MapLibre GL + OpenFreeMap

## Engine vs Data

- **Engine**: `maplibre_gl ^0.28.0` (Flutter plugin, native MapLibre SDK)
  - Android: MapLibre Native (API 21+/Android 5, JDK 21, NDK, hardware accel)
  - iOS: MapLibre Native (iOS 13+)
  - Web: maplibre-gl-js (WebGL2)
  - License: MIT, verified publisher `maplibre.org`
  - No Google Maps SDK, no Cloud Billing, no API key, no Map ID
- **Data**: OpenFreeMap vector tiles
  - Endpoint: `https://tiles.openfreemap.org/planet` (OpenMapTiles schema, OSM data via Planetiler)
  - Styles: hosted reference `https://tiles.openfreemap.org/styles/{liberty|positron|bright}` but **local JSON overrides** for full control
  - Sprite: `https://tiles.openfreemap.org/sprites/ofm_f384/ofm`
  - Glyphs: `https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf`
  - No key, no billing, unlimited for mobile with unique User-Agent

The engine renders vector tiles; the data provider supplies them. Swapping provider does not require engine change.

## Style Source & File Locations

- **Local Style JSON** (fully customizable, no Cloud Map ID):
  - `assets/map_styles/luqma_light.json` — Light Ivory theme
  - `assets/map_styles/luqma_dark.json` — Dark Charcoal theme
  - Registered in `pubspec.yaml` `assets: - assets/map_styles/`
  - Referenced in `lib/core/map/maplibre_config.dart` as `lightStyleAsset`/`darkStyleAsset`
- **Config**:
  - `lib/core/map/maplibre_config.dart` — isolated `MapStyleProvider` abstraction (`OpenFreeMapProvider`), `MapLibreConfig` with Sohag fallback (26.56/31.69, zoom 14), zoom 3–18, brand Burgundy `#7B1E28`
  - Runtime: `MapLibreConfig.loadStyleString(brightness)` loads JSON via `rootBundle`; `isValidStyleJson` validates version 8 + `openmaptiles` source + layers

## Color Edit Path

Styles are plain MapLibre Style Spec JSON (version 8). Each visual class is an independent layer:

- **Background**: `background` → `#FAF7F0` (light) / `#1A1A1A` (dark, never pure black)
- **Landuse**: `landuse-residential`, `landuse-industrial` → warm ivory / dark neutral
- **Parks**: `park`, `park-outline` → `#D8E3D0` / `#1F2B1F`
- **Water**: `water`, `waterway` → `#B8D4E3` / `#1E2A32`
- **Buildings**: `building`, `building-3d` → `#E8E0D1`/`#D6CFC0` outline (light), `#2A2A2A`/`#333333` (dark)
- **Boundaries**: `boundary-country`, `boundary-state` → `#D6CFC0` / `#3A3A3A`
- **Roads**: separate casing + fill per class for fine control
  - Minor `road-minor(-casing)` → `#D8D0BA`/`#D6CFC0` (light), `#3A3A3A`/`#333333` (dark)
  - Secondary `road-secondary(-casing)` → `#EBE5D6`/`#D6CFC0` (light), `#2E2E2E`/`#333333` (dark)
  - Primary `road-primary(-casing)` → `#FFFFFF`/`#D6CFC0` (light), `#2A2A2A`/`#333333` (dark)
  - Trunk/Motorway `road-trunk(-casing)`, `road-motorway(-casing)` → white/`#C8BFA8` (light), `#2A2A2A`/`#444444` (dark)
- **POIs**: `poi-restrained` → rank 1 only, minzoom 15, restrained (`#8A7A6A`/`#8A8A8A`)
- **Labels**: `road-label`, `place-city/town/village`, `water-label` → `#5A4A44`/`#6B5D4F` (light), `#9E9E9E`/`#8A8A8A` (dark), `#4A6B7A`/`#6B8291` for water
- **Brand**: Burgundy `#7B1E28` for marker + recenter (via `AppSemanticColors.primary`, `MapLibreConfig.burgundy`)

To change a color: edit the corresponding `paint.fill-color`/`line-color`/`text-color` in both JSONs (keep contrast), ensure `glyphs`/`sprite` unchanged, then hot-reload. No native rebuild needed.

## Attribution

Required per OpenFreeMap / OpenMapTiles / OSM ODbL:

- Displayed: `© OpenFreeMap © OpenMapTiles Data © OpenStreetMap contributors`
- Location: `lib/core/map/maplibre_config.dart` `OpenFreeMapProvider.attribution`, `MapLibreConfig.attribution`, `lib/core/localization/translations/address_translations.dart` `mapPickerAttribution`, and `MapLocationPickerPage` bottom-left chip (`Key('map_picker_attribution')`)
- Style JSON `metadata.openfreemap:provider` also notes source

Never remove or hide attribution; it is legal requirement.

## Limitations

- No geocoding / reverse-geocoding / routing / Places built-in (intentionally excluded; use `Geolocator` + manual `POST /api/Address/Create` flow)
- No auto reverse-geocode, no background location permission
- Offline limited to MapLibre cache (not configured; network required for tiles)
- OpenFreeMap: no SLA, fair-use (≤3000 tiles/50 MB offline, 4 parallel, unique UA)
- Android API 21+, iOS 13+, WebGL2 required; desktop targets unsupported by `maplibre_gl` (use `maplibre` package if needed later)

## Provider Swap

1. Implement `MapStyleProvider` with new `vectorTileUrl`, `spriteUrl`, `glyphsUrl`, `attribution`, `name`
2. Change `MapLibreConfig.provider` constant
3. If schema differs, update `assets/map_styles/*.json` `sources` URL and layer `source-layer` names
4. No map widget code change (`MaplibreMap` + `MapStyleProvider` abstraction)

For self-hosted Planetiler: point `vectorTileUrl` to your tile server, keep style JSON local.

## Verification (SDK missing = NOT RUN)

- `flutter pub get` — NOT RUN (no `/opt/flutter` in CI image; run locally after `maplibre_gl` add)
- `dart format` — NOT RUN
- `flutter analyze` — NOT RUN
- `flutter test` — NOT RUN; 13 test groups updated to expect `© OpenFreeMap` and `MapLibreConfig` styles, no Google SDK

Manual verification: `git diff --check` clean, `grep -R google_maps` zero, `lib/core/map/maplibre_config.dart` isolated, `assets/map_styles/*.json` valid JSON version 8.

