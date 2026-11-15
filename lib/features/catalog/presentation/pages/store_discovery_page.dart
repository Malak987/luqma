import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/catalog_route_arguments.dart';
import '../widgets/store_discovery_view.dart';

/// Route page for a main category chosen on Home. The matching
/// [StoreDiscoveryCubit] is provided by the router.
class StoreDiscoveryPage extends StatelessWidget {
  const StoreDiscoveryPage({required this.arguments, super.key});
  final StoreDiscoveryArguments arguments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = l10n.catalog;
    final arabic = l10n.locale.languageCode == 'ar';
    return StoreDiscoveryView(
      title: arabic ? arguments.nameAr : arguments.nameEn,
      searchHint: copy.searchStores,
      sectionTitle: copy.suggestedStores,
      sectionHint: copy.suggestedStoresHint,
    );
  }
}
