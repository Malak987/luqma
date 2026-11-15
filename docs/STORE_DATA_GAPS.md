# Store discovery data gaps

This note records fields requested by the store discovery and store details
designs that are not present in the current Store GET response/model. The UI
must continue to show only values supplied by the API; it must not infer,
estimate, or display sample values for these fields.

## Available today

The current `Store` model contains the store ID, Arabic and English names,
main category ID and localized names, active/open-now flags, image URL,
address, and phone number. Cuisine filtering is loaded from the existing
Cuisine endpoint. Menu item responses contain item descriptions, images,
prices, compare-at prices, weight information, options, and add-ons.

## Requested fields not available on Store

| Field | Suggested API/database representation | Notes |
| --- | --- | --- |
| Rating | `ratingAverage` (decimal) and `ratingCount` (integer) | Average and count should be returned together; define rounding and no-review behavior. |
| Delivery time | `deliveryTimeMinMinutes` and `deliveryTimeMaxMinutes` (integers) | A range avoids presenting an unqualified estimate. Define whether values are live or configured estimates. |
| Distance | Prefer calculating from store coordinates and the selected delivery location; expose `latitude` and `longitude` on Store if absent | Distance depends on the user's active address and should not be stored as a fixed store attribute. Define routing/straight-line semantics. |
| Discount | Explicit promotion data, e.g. `discountPercent`, `promotionLabelAr`, `promotionLabelEn`, `promotionStartsAt`, `promotionEndsAt` | Define eligibility, time zone, and whether the discount applies to all items or selected products. Do not derive discounts from menu compare-at prices at store level. |
| Tags | Localized tag records with stable IDs, e.g. `tags: [{ id, nameAr, nameEn }]` | Define the allowed tag vocabulary and whether tags are filterable. |

## Before adding these fields

Agree on nullability, validation, localization, ownership, and update rules;
then update the API contract, persistence schema, response model, domain entity,
and tests together. Until then, hide these metadata slots in the UI.
