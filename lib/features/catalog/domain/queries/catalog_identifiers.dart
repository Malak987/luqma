/// IDs remain opaque UUIDs. This is validation, not a display formatter.
final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isCatalogId(String value) => _uuid.hasMatch(value);
