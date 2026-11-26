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
| Identity | `nameAr`, `nameEn` |
| Card cover image | `images[0]`, then `iconUrl`, then the Luqma placeholder |
| Logo badge | `iconUrl` |
| Category | `mainCategoryNameAr`, `mainCategoryNameEn` |
| Cuisines | nested `cuisines[].nameAr`, `cuisines[].nameEn` |
| Description | `descriptionAr`, `descriptionEn` |
| Rating and review count | `averageRating`, `ratingsCount` |
| Distance | `distanceKm` |
| Live operational status | `isOpenNow` |
| Opening hours | `openTime`, `closeTime` (`HH:mm:ss`) |
| Delivery | `deliveryTimeMinutes`, `deliveryFee` |
| Price level | `priceLevel` — a positive integer band (`2` → `$$`); display text is kept as supplied |
| Google Maps action | `latitude`, `longitude`, with `address` as a fallback query |

The existing `priceFrom` and `priceTo` snapshot values remain dedicated to the
price-range filter/store details. They are not reinterpreted as a price level.

## Zero means "not provided"

`Store/GetAll` publishes `0` for values the store has not filled in yet:
`averageRating`, `ratingsCount`, `deliveryTimeMinutes`, `deliveryFee`, `latitude`,
`longitude`. These are never rendered as `0`, `Free delivery`, or a `0 km`
distance; the UI omits the element instead. `isOpenNow == null` stays unknown and
is never rendered as Closed. Only an explicit `isOpenNow: false` shows Closed,
together with the next opening time taken from `openTime`.

## Store photos

`images` is the owner-uploaded gallery. The card cover follows a strict
priority: `images[0]` when it is an absolute `http`/`https` URL, otherwise
`iconUrl`, otherwise the Luqma placeholder. The list is never searched for
another entry — a blank or broken first item falls straight to the logo — so a
card never shows a photo the owner did not list first.
Unusable entries are skipped while parsing, so one bad URL cannot break the
response or shift the card layout.

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
