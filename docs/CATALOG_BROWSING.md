# Catalog browsing — Store Discovery and store menu handoff

## Scope and evidence

Implemented on **`arena/612cfe7f-luqma`**. The user's confirmed MenuCategory/MenuItem Swagger GET contracts now resolve the earlier menu-schema gate. Store Details renders real menu results through Domain → Data → Presentation; its old “menu unavailable” placeholder and obsolete test assertions have been replaced.

- Contracts come from the user, including **Cuisine/MenuCategory direct `data` arrays** and **Store/MenuItem `data.items` pages**. There are no alternate-wrapper guesses or Create-DTO-derived GET fields.
- **No live API/Swagger/database calls were made.** Fixtures are synthetic, confined to tests, and are not evidence of deployed responses.
- Screenshots were available and viewed: `Frame 73.png`, `Luqma - تفاصيل الطبق والخيارات (Dark Mode).png`, and `Luqma - تصفية البحث (Dark Mode).png` in `/tmp/arena-coding-uploads/`. They inform visual hierarchy, not API fields. No device, golden or pixel-perfect comparison was possible without Flutter.
- No new dependency, lockfile change, localization migration, theme rewrite, production sample data, cart request or speculative endpoint.
- Existing MainCategory work, Home, Store Discovery implementation and snapshot header were preserved in this menu phase. Shared DioClient, startup/Splash/Onboarding, authentication/session and address gates remain unchanged. Browsing still starts from the existing gated Home.
- Implementation checks below were recorded before publication, starting from `1898c7b2baf909b0c188862f0e448bc400d2a137`. The user subsequently authorized committing, pushing and opening a pull request for the branch's complete changes. See repository history and the pull request for publication status; no merge or deployment is included.

## Requests and exact decoding

All use the existing base `https://luqma-api.runasp.net`, shared DioClient and constants.

| Operation | Parameters | Success `data` |
| --- | --- | --- |
| Existing `GET /api/Cuisine/GetAll` | `onlyActive=true` | Direct cuisine array |
| Existing `GET /api/Store/GetAll` | Actual `mainCategoryId`, `isActive=true`, `pageNumber`, `pageSize`; selected `cuisineId` only; `isOpenNow=true` only when enabled | Page object with `items` |
| **New `GET /api/MenuCategory/GetAll`** | Actual `storeId`, `onlyActive=true` | **Direct category array**, never `data.items` |
| **New `GET /api/MenuItem/GetAll`** | Actual `storeId`, `isActive=true`, `pageNumber`, `pageSize`; optional parameters below | **Page object with `items`**, never a root page |

MenuItem optional parameters:

- **All categories:** omit `menuCategoryId` entirely. A selection sends its actual UUID, not its translated label or list index.
- Nonblank trimmed `search`; cleared/blank search is omitted. Search input uses a route-owned, disposed 350ms UI debounce; keyboard submission applies immediately.
- `minPrice` / `maxPrice` only when supplied, including a legitimate zero. UI accepts Arabic/Persian numerals and Arabic decimal input, converts to numbers, and rejects nonfinite/negative/reversed bounds before querying. Clearing a bound omits that key.
- “On sale only” ON sends `onSale=true`; OFF omits it to browse all products.
- **No `sortBy` is exposed or sent.** Its accepted values have not been supplied; arbitrary enum strings and screenshot-derived recommendation/order semantics are not invented.

Every menu page keeps the same store, category, search, price and sale scope. No client filtering substitutes a partial page for backend-filtered results or rewrites pagination totals.

These are public browsing GETs: no auth opt-in extras, manual bearer/header, token reads, new session behavior or signout. The unchanged DioClient strips stale Authorization for anonymous requests. Network/HTTP/envelope/format failures become localized section failures; raw backend text/UUIDs are not customer labels or errors.

### Confirmed category fields

`id`, `storeId`, `nameAr`, `nameEn`, nullable `imageUrl`, `displayOrder`, `isActive`, `itemsCount`.

Active results are deduplicated by actual UUID and sorted by `displayOrder` ascending (ID is only a deterministic tie-breaker). Store relationship mismatches fail rather than display another store's categories. **`itemsCount` remains metadata; it never substitutes for product requests/results.**

### Confirmed product fields

- `id`, `menuCategoryId`, `menuCategoryNameAr`, `menuCategoryNameEn`.
- `nameAr`, `nameEn`, `descriptionAr`, `descriptionEn`, numeric `price`/`compareAtPrice`, `imageUrl`, `isActive`, `isSoldByWeight`, nullable numeric `weight`.
- `options`: independent `id`, `nameAr`, `nameEn`, numeric `price`.
- `addons`: independent `id`, `nameAr`, `nameEn`, numeric `price`, optional artwork.
- Missing/null optional arrays become immutable empty lists; a supplied wrong array/value type fails visibly. Missing/null `weight` remains null. Required malformed fields are not silently fabricated. Failed envelopes are handled before decoding their `data`.
- Page metadata is preserved exactly: `pageNumber`, `totalPages`, `totalCount`, `hasPreviousPage`, `hasNextPage`. Response page, active status and selected category consistency are checked. GET items have no `storeId`; one is not fabricated on the entity. Store scope is sent with every request.

## Implemented Store Details behavior

1. Typed route validation runs before resolving dependencies. The actual passed `Store` snapshot still renders through the **unchanged `StoreDetailsHeader`**. There is no `Store/GetById` or header refetch.
2. Route-scoped menu state starts active category loading and the first active **All categories** product page concurrently. Category loading/failure/empty feedback cannot hide products; each section has its own explicit retry.
3. Category chips filter products **in place**, without a separate category screen. New category/search/price/sale filters atomically clear old products, metadata and paging errors and restart the configured first page.
4. A persistent products heading/anchor exists in loading, success, empty and error states. Category changes reveal it with a 220ms animation, or an immediate reveal for disabled animations/accessibility navigation. Search typing does not force-scroll the focused field away.
5. Lazy slivers initially request one page. Only user scrolling toward the end within 360 logical pixels requests continuation. A localized Show more action supports keyboard/accessibility use and valid empty intermediate pages. There is no eager page-draining loop or short-page end heuristic.
6. Duplicate initial/append calls are guarded. Store/filter generations reject stale successes **and failures**, including stale appends and A → B → A changes. Completed transport calls may still finish, but cannot mutate the wrong scope or a closed Cubit.
7. Appends deduplicate IDs case-insensitively, retain order, and replace repeated snapshots. Page advancement is success-only. A failed next page preserves loaded list/index identity, metadata and selected filters and exposes an **explicit same-page retry**; scroll cannot cause retry storms. Backend `hasNextPage` controls continuation, never returned item count.
8. Product rows/sheets show actual localized names/descriptions, bounded artwork/fallbacks and numeric prices. Crossed-out comparison and sale labeling require an actual finite `compareAtPrice > price`. No invented currency, discount percentage, ratings, delivery or favorites.
9. A local product details sheet exposes **one optional option choice** and **independent addon selections**. Separate option ID and addon-ID set are preserved even when namespaces share the same string. Option prices are not assumed additive; addon prices are displayed as additional amounts. Reopening retains saved selections for this store route; canceled edits are not applied and removed choices are sanitized against the actual product snapshot.
10. “Save choices” is explicitly **local UI only**, not Add to cart. No total calculation, quantity/notes/checkout contract, submit request or cart count is fabricated. Leaving/changing store discards route-local choices; late sheet results cannot restore choices to a changed store context.
11. `isSoldByWeight` and a supplied nullable `weight` are displayed honestly. **No weight unit, selector, min/max/step or Create-only configuration is assumed.**

## Preserved Discovery and navigation

Home still passes the actual MainCategory UUID and both names into discovery. Discovery retains its independent cuisine/store states, All/cuisine selection, Open Now omission semantics, backend-authoritative open status, lazy metadata-driven paging, duplicate/stale guards and retained-results retry. Its Cubit, state, page, result/filter/card widgets, Domain/Data and existing paging tests were not rewritten for menus.

Pushing details keeps the prior Discovery Cubit, filters, pages and scroll state alive. Popping details disposes only its menu Cubit; revisiting resolves a fresh one. The Discovery navigation test now expects the two authorized menu loads instead of the obsolete no-menu assumption, while retaining snapshot/back/no-discovery-reload assertions.

## Architecture, composition and rebuild boundaries

- **Domain:** pure Dart/Equatable entities, filters/query, repository contract and constructor-injected use cases. No Flutter, Dio, JSON, Data or Presentation imports. Existing Home Domain dependencies/debt were not refactored.
- **Data:** exact envelope/DTO parsing, confirmed HTTP parameters, entity mapping and Failure mapping. Reuses the existing catalog primitives/envelope and generic Domain `CatalogPage`.
- **Presentation:** `StoreMenuCubit` receives only the two menu use cases, store ID and `CatalogPaging`. Widgets own UI drafts/controllers/local choices, not HTTP or repositories. There are no locator calls inside widgets or Cubits.
- Guarded lazy singletons in existing GetIt composition: `StoreMenuRemoteDataSource`, `StoreMenuRepository`, `GetActiveMenuCategoriesUseCase`, `GetMenuItemsUseCase`. Existing `CatalogPaging` is reused.
- Guarded `registerFactoryParam<StoreMenuCubit, String, void>` receives the actual store ID. Router `BlocProvider(create: ...)` owns disposal, not a global menu singleton.
- Category/selection and sale controls use narrow selectors. Footer subscribes to three booleans and uses compatible optional product labels on the existing `PaginationFooter`; Discovery defaults are unchanged.
- The result sliver rebuilds only on content/status/initial failure changes. Lazy child widget identities and per-ID O(1) entity selectors keep unchanged cards from rebuilding for footer updates or another card's change; the immutable index is reused on footer-only changes. Removed/filter-reset tiles are evicted from the route cache.
- Shared artwork uses existing `AppNetworkImage`/Image.network/ImageCache with fixed bounds and fallback, not another loader/preload package. Shared feedback, choice selector, section heading and pagination presentation are reused. Product facts/artwork are shared between rows and sheet.

### Runtime localization, theme and sizing

Arabic/English copy and both versions of fetched content remain available. Locale/theme changes update visible labels/content, number digits, Directionality, alignment and Material back/close behavior **without refetching or resetting filters/pages**. IDs are only identities/query values/keys, never customer fallback copy or semantics.

UI uses existing typography, radii, spacing and semantic light/dark colors, including Luqma burgundy **`#7B1E28`**, cream **`#F6F1E7`** and gold **`#C89F6A`**. Product cards switch to a stacked layout for narrow/scaled text; price controls also stack. Content is bounded to 760 logical pixels, text wraps, lists remain lazy, owned controllers/debounce are disposed, and category/sheet transitions respect reduced-motion settings. This is implemented behavior with authored tests, **not an executed visual/overflow certification**.

### Paging assumptions (unchanged configuration)

Injected defaults remain **first page 1, size 20**, configurable with:

```text
--dart-define=LUQMA_CATALOG_FIRST_PAGE=1
--dart-define=LUQMA_CATALOG_PAGE_SIZE=20
```

These are conservative client defaults, not independently verified backend defaults/maxima. First page must be nonnegative and size positive. No guessed maximum is imposed. Successful response metadata remains authoritative.

## Tests authored and actual validation

Seven new executable test files plus one shared menu fixture file cover:

| Area | Authored coverage — not executed here |
| --- | --- |
| Models | Category direct-array and product nested-page contracts; all metadata; bilingual names/descriptions; numeric prices; nullable weight; separate options/addons; optional arrays/artwork; immutable lists; malformed wrappers/fields; sale comparison; failed envelopes |
| Data source | Exact GET paths/active/store/page parameters; All and blank/default omissions; selected UUID/search/zero and decimal prices/sale; no `sortBy`; anonymous stale-header stripping/no-token/no-session-clear behavior; network/timeouts/cancel/HTTP/format/envelope failures |
| Repository/use cases | Mapping, immutable outputs and Failure propagation; real store/category/page forwarding; active ordered category snapshots; invalid queries rejected before repository; page/active/category scope consistency |
| Cubit | Independent first loads/retries; duplicate/coalesced calls; atomic filter reset; filter preservation across appends; category counts only metadata; dedupe; authoritative short/empty pages; retained content/index retry; stale category/filter/append/store responses including A → B → A; removed selected category; configurable paging; invalid store; closed initial/append safety |
| DI/routes/navigation | Guarded/idempotent lifetimes and overrides; fresh actual-store factories; no load on resolution; per-visit disposal; typed invalid-route protection; exact snapshot/no GetById; Discovery survives details/back |
| UI | Persistent category reveal including reduced motion; lazy near-end append/retained offset; unchanged card/header/category widget identities; footer retry; debounced search/Arabic prices/sale; local saved option/addon IDs/reopening; no cart request; Arabic/English, light/dark, RTL/LTR and 320px/200% text with options/addons; locale/theme no-refetch retention; debounce disposal |

Existing snapshot/header, route and Discovery navigation tests were updated narrowly for the now-authorized menu flow. Unrelated MainCategory/startup/address/Home tests and baseline debt were not weakened.

**Implementation checks actually run in this workspace before publication:**

- WASM formatter **`@wasm-fmt/dart_fmt@0.4.0`**, language mode `3.6.0`, width 80: **81 cumulative browsing Dart files parsed/formatted and idempotence checked, zero parse/idempotence errors**; 37 are authored/touched in this menu phase. This is **not Dart type analysis**. Tooling is outside project dependencies.
- Static local-import/layer/whitespace audit: **81 Dart files, zero issues**. This is not a substitute for an analyzer.
- Pre-menu hash audit: **475 existing files, no unexpected edits or deletions**; only the explicitly inventoried menu integration/test/doc paths are changed. All other existing content, including MainCategory, Discovery and the header, is preserved from this phase's starting snapshot. This does not reconstruct an older unavailable preservation manifest.
- `pubspec.yaml`, `pubspec.lock`, shared DioClient, app startup and address gate also compare byte-for-byte to the base commit `1898c7b2baf909b0c188862f0e448bc400d2a137`.
- `git diff --check`: clean. At the implementation handoff, branch/HEAD were unchanged and no files were staged; publication was authorized afterward.
- **`flutter analyze`: could not start, exit 127 — `flutter: command not found`.**
- **Targeted `flutter test` command: could not start, exit 127 — same missing SDK. No Flutter tests executed or claimed passing.**
- **Native `dart format`: could not start, exit 127 — `dart: command not found`.** WASM parsing/formatting is the available fallback, not native build/test validation.

The lockfile requires **Dart >=3.13.0 / Flutter >=3.47.0**. Neither SDK is installed; no lockfile downgrade or fake preview was used. Native analysis/build, actual API interoperability and screenshot/device/golden validation remain unverified.

On a compatible SDK, retain the lockfile and run:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test test/features/catalog \
  test/core/di/service_locator_catalog_test.dart \
  test/core/di/service_locator_store_menu_test.dart \
  test/core/routing/catalog_routes_test.dart \
  test/core/widgets/app_network_image_test.dart \
  test/features/home/presentation/pages/home_catalog_navigation_test.dart
flutter test
```

Also run native `dart format --output=none --set-exit-if-changed` over the catalog/integration/test paths and smoke-test the public endpoints, rapid category/filter/store changes, empty/short continuation, offline footer retry, product choice reopening, locale/theme retention, reduced motion and back navigation on a device/emulator. Existing unrelated Home rating/delivery test debt is not a claimed pass/failure without execution.

## Remaining boundaries — not blockers for menu browsing

- Accepted backend **`sortBy` values** are still needed before connecting sorting.
- No confirmed **currency or weight unit/configuration** is present in GET. Numeric prices/weight are displayed without invented units. Create-only weight min/max/step remain excluded.
- No verified **cart/submit contract or option total-price rule** exists in this repository. Product choice interaction is route-local UI only. A real cart integration needs its own confirmed contract and authorization.
- Deployment first-page/default/max page-size conventions and full Store nested cuisines/hours/timezone/overnight semantics remain unverified. They do not block this implemented subset, and backend `isOpenNow` remains authoritative.

## Actual menu-phase file inventory

This is the delta from the completed Discovery/snapshot work, **not the full branch inventory**. The branch also includes the earlier MainCategory and Discovery changes.

### New production Dart files (20)

- `lib/features/catalog/domain/entities/menu_category.dart`
- `lib/features/catalog/domain/entities/menu_item.dart`
- `lib/features/catalog/domain/queries/menu_item_filters.dart`
- `lib/features/catalog/domain/queries/menu_item_query.dart`
- `lib/features/catalog/domain/repositories/store_menu_repository.dart`
- `lib/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart`
- `lib/features/catalog/domain/usecases/get_menu_items_use_case.dart`
- `lib/features/catalog/data/datasources/store_menu_remote_data_source.dart`
- `lib/features/catalog/data/models/menu_json.dart`
- `lib/features/catalog/data/models/menu_category_model.dart`
- `lib/features/catalog/data/models/menu_category_response_model.dart`
- `lib/features/catalog/data/models/menu_item_model.dart`
- `lib/features/catalog/data/models/menu_item_page_model.dart`
- `lib/features/catalog/data/repositories/store_menu_repository_impl.dart`
- `lib/features/catalog/presentation/cubit/store_menu_cubit.dart`
- `lib/features/catalog/presentation/cubit/store_menu_state.dart`
- `lib/features/catalog/presentation/widgets/menu_filters.dart`
- `lib/features/catalog/presentation/widgets/menu_item_card.dart`
- `lib/features/catalog/presentation/widgets/menu_item_details_sheet.dart`
- `lib/features/catalog/presentation/widgets/menu_item_results_slivers.dart`

### New test/support Dart files (8)

- `test/core/di/service_locator_store_menu_test.dart`
- `test/features/catalog/data/menu_models_test.dart`
- `test/features/catalog/data/store_menu_remote_data_source_test.dart`
- `test/features/catalog/data/store_menu_repository_impl_test.dart`
- `test/features/catalog/domain/menu_use_cases_test.dart`
- `test/features/catalog/presentation/cubit/store_menu_cubit_test.dart`
- `test/features/catalog/presentation/pages/store_menu_page_test.dart`
- `test/features/catalog/support/menu_fixtures.dart`

### Existing paths modified in this phase (10, including this handoff)

- `lib/core/network/api_constants.dart` — only the two confirmed menu GET constants added.
- `lib/core/di/service_locator.dart` — guarded menu registrations/factory; existing lifetimes and MainCategory/Discovery chain retained.
- `lib/core/routing/app_router.dart` — validated Store Details route now owns the menu Cubit; passed snapshot retained.
- `lib/core/localization/translations/catalog_translations.dart` — bilingual menu/filter/product/choice copy and number display; obsolete unavailable copy removed.
- `lib/features/catalog/presentation/pages/store_details_page.dart` — snapshot header plus independent menu sections, owned scrolling/anchor/local choices.
- `lib/features/catalog/presentation/widgets/pagination_footer.dart` — optional product copy overrides; unchanged defaults for Discovery.
- `test/core/routing/catalog_routes_test.dart` — actual menu context, snapshot retention and provider lifetime assertions.
- `test/features/catalog/presentation/pages/store_details_page_test.dart` — inject menu dependency; retain header/metadata/theme/localization assertions, replace obsolete no-menu assertion.
- `test/features/catalog/presentation/pages/store_discovery_page_test.dart` — narrow details/back test update for real menu composition; Discovery paging/filters unchanged.
- `docs/CATALOG_BROWSING.md` — current contracts, implementation, validation limits and inventory.
