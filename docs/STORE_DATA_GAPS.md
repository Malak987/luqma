# Store discovery data contract and gaps

Customer-facing store cards consume only data returned by the existing
`GET /api/Store/GetAll` response. The Flutter app does not calculate ratings,
distance, delivery values, opening status, price level, or promotions.

## Card fields consumed from Store/GetAll

The Store model safely accepts these optional fields when the API supplies
them. A missing, null, invalid, or inapplicable value leaves its UI element
hidden.

| Card content | Store API field(s) |
| --- | --- |
| Identity and image | `iconUrl`, `nameAr`, `nameEn` |
| Category | `mainCategoryNameAr`, `mainCategoryNameEn` |
| Cuisines | nested `cuisines[].nameAr`, `cuisines[].nameEn` |
| Description | `descriptionAr`, `descriptionEn` |
| Rating and review count | `averageRating`, `ratingsCount` |
| Distance | `distanceKm` |
| Live operational status | `isOpenNow` |
| Delivery | `deliveryTimeMinutes`, `deliveryFee` |
| Price level | `priceLevel` (displayed as supplied; no numeric/enum mapping is inferred) |
| Google Maps action | `latitude`, `longitude`, with `address` as a fallback query |

The existing `priceFrom` and `priceTo` snapshot values remain dedicated to the
price-range filter/store details. They are not reinterpreted as a price level.

## Deliberately unavailable: store discount

The current `Store/GetAll` response/model has no store-level discount,
promotion label, active flag, eligibility rule, or validity window. Therefore
no external store card displays a discount badge. The card has an optional
presentation slot for a future real promotion response, but no percentage or
marketing copy is derived from item prices, price level, descriptions, or any
other unrelated field.

A future contract should explicitly define a store promotion payload, for
example `discountPercent`, localized labels, active/eligibility state, and
start/end dates with timezone semantics. Only then should that payload be
mapped through data and domain layers and passed to the card.

## Location safety

The app opens a Google Maps search URL only for finite in-range coordinates
that are not `0,0`. If those coordinates are absent or invalid, it uses a
meaningful API address as an encoded Google Maps search query. With neither,
the location action is omitted.
