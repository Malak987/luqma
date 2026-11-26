# Cart — backend guarantees required for full enforcement

The Flutter client implements every rule it can verify locally. The rules
below cannot be guaranteed by a client alone; they are documented here as
requirements on the Cart API rather than implemented as speculative
client-side workarounds. Nothing in this document changes the API contract.

## One restaurant per cart (mandatory)

The cart must contain items from a single restaurant only.

- Requirement: the backend must reject an AddToCart whose menu item belongs
  to a different restaurant than the one already represented in the caller's
  cart, with a dedicated, distinguishable error (e.g. a restaurant-conflict
  code), and must never silently clear or replace the existing cart.
- The current Swagger surface (`GetMyCart`: `items`, `totalQuantity`,
  `subTotal`; `GetCount`: `linesCount`, `totalQuantity`; cart lines: no
  restaurant field) does **not** expose a restaurant identity, so the client
  cannot detect a conflict without inventing an undocumented field or
  calling an undocumented endpoint. The client therefore does not attempt
  client-side detection.
- Until the backend enforces (or exposes) this, cross-restaurant adds will
  be processed wherever the backend permits them; the cart UI will not
  silently clear the cart in any case.

## Exact-configuration line identity and merging

The required semantics (confirmed by the documented contract samples only in
part):

- `AddToCart` must merge into the existing line for the exact
  `menuItemId` + `menuItemOptionId` + unordered `addonIds` configuration; it
  must not create a second identical line. If identical configurations can be
  added as duplicate lines, the client cannot reconcile them reliably.
- `UpdateToCart` must target the exact same configuration
  (`menuItemOptionId`, including explicit null, plus unordered `addonIds`) —
  positive quantity updates that line, `0` removes that line only, and a
  successful removal may report `isRemoved: true` (already handled: the
  client parses only `isRemoved` and refreshes from `GetMyCart`).
- The 99-quantity maximum must be enforced atomically server-side (1-99 per
  exact configuration). Client-side validation rejects `> 99` and coalesces
  rapid stepper taps to 99, but cannot prevent races across devices,
  sessions, or retries.
- If the server clamps instead of rejecting, the next `GetMyCart` snapshot
  reconciles the displayed quantity (the client never trusts its own pending
  values over an authoritative snapshot).

## Concurrency and idempotency

- `AddToCart` retried after an ambiguous network failure may apply twice if
  the server commits before the client times out. The client deliberately
  never auto-retries AddToCart for this reason; idempotent server behavior
  (or an idempotency key honored by the API) would close this gap.
- `UpdateToCart` is idempotent for a given absolute target quantity (it sets
  rather than increments), so the client's per-line serialized queue is
  safe; however, two devices editing the same line can interleave, and the
  backend is the only place a total ordering can be enforced.
- `Clear` returning only `200` leaves the client no way to distinguish an
  empty success from an envelope error. The client accepts an empty body as
  success and otherwise validates the standard cart envelope; a documented
  response body would allow stricter handling.

## What Flutter enforces today

- Quantity bounds 1-99 for Add, 0-99 for Update; negative and >99 rejected
  before any request; every client stepper (cart tile, catalog in-row and
  details-sheet quantity pickers) clamps targets to 99.
- Exact-configuration identity for client-side bookkeeping: sorted add-on
  IDs + nullable option + menu item (case-insensitive), used to serialize
  per-line mutations and merge responses.
- Per-line request ordering, response-clobbering prevention (newer requested
  quantities are never overwritten by older confirmations), and rollback of
  the optimistic display to the last confirmed state on failure.
- Authoritative reconciliation via `GetMyCart` + `GetCount` after every
  confirmed mutation; older fetches cannot replace newer snapshots; the badge
  projects pending changes and returns to the `GetCount` value on reconcile.
- Unavailable items cannot be increased but can be decreased/removed;
  removed items are read-only.
