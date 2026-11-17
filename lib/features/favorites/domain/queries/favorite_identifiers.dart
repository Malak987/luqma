final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Menu item IDs are opaque UUIDs throughout the supplied Favorites contract.
bool isFavoriteMenuItemId(String value) => _uuid.hasMatch(value);
