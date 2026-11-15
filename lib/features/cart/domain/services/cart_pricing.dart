import '../../../catalog/domain/entities/menu_item.dart';

/// Single place that decides what one unit of a menu item costs.
///
/// Assumptions (to be confirmed with the backend, see BACKEND_MISSING_DATA.md):
/// * a selected option is a variant, so its price replaces the base price;
/// * addons are additive.
abstract final class CartPricing {
  static num unitPrice({
    required MenuItem item,
    String? optionId,
    Set<String> addonIds = const <String>{},
  }) {
    num total = item.price;
    if (optionId != null) {
      for (final option in item.options) {
        if (option.id == optionId) {
          total = option.price;
          break;
        }
      }
    }
    for (final addon in item.addons) {
      if (addonIds.contains(addon.id)) {
        total += addon.price;
      }
    }
    return total;
  }
}
