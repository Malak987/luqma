import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/translations/address_translations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../../domain/entities/address.dart';
import '../cubit/address_setup_cubit.dart';
import '../cubit/address_setup_state.dart';
import 'address_list_view.dart';

/// Opens the delivery-address sheet from the Home header.
///
/// Returns the address the user picked, or null when the sheet is dismissed.
/// The sheet never builds an address itself: it reuses the persisted list, the
/// existing map picker (create) and the existing details page (create/update).
Future<Address?> showAddressManagerSheet(BuildContext context) {
  // A modal route lives in the navigator overlay, above the screen that owns
  // the address cubit, so the cubit is handed to the sheet explicitly.
  final cubit = context.read<AddressSetupCubit>();
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider<AddressSetupCubit>.value(
      value: cubit,
      child: const _AddressManagerSheet(),
    ),
  );
}

class _AddressManagerSheet extends StatelessWidget {
  const _AddressManagerSheet();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context).address;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.managerTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: colors.headingText,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.managerSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('address_manager_close'),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.close_rounded, color: colors.mutedText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<AddressSetupCubit, AddressSetupState>(
                builder: (context, state) => _content(context, state, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AddressSetupState state,
    AddressTranslations l10n,
  ) {
    final cubit = context.read<AddressSetupCubit>();

    switch (state.status) {
      case AddressSetupStatus.initial:
      case AddressSetupStatus.loading:
        return Center(
          key: const Key('address_manager_loading'),
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case AddressSetupStatus.error:
        return _Message(
          key: const Key('address_manager_error'),
          icon: Icons.cloud_off_outlined,
          message: l10n.loadFailed,
          action: AppButton(
            key: const Key('address_manager_retry'),
            text: l10n.retry,
            onPressed: cubit.load,
          ),
        );
      case AddressSetupStatus.empty:
        return _Message(
          key: const Key('address_manager_empty'),
          icon: Icons.location_off_outlined,
          message: l10n.emptyMessage,
          action: AppButton(
            key: const Key('address_manager_add_empty'),
            text: l10n.addAddress,
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: () => _addAddress(context),
          ),
        );
      case AddressSetupStatus.populated:
        final selected = state.selectedAddress;
        return AddressListView(
          addresses: state.addresses,
          selectedId: selected?.id,
          onSelect: (address) {
            cubit.selectAddress(address.id);
            Navigator.of(context).pop<Address>(address);
          },
          onEdit: (address) => _editAddress(context, address),
          onAddAddress: () => _addAddress(context),
        );
    }
  }

  Future<void> _editAddress(BuildContext context, Address address) async {
    final cubit = context.read<AddressSetupCubit>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final saved = await AppRouter.pushNamed<Address>(
      context,
      AppRoutes.addressEdit,
      arguments: address,
    );
    if (saved == null || !context.mounted) return;
    // Update the shared list and the Home header without another request.
    cubit.onAddressSaved(saved);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('address_manager_updated'),
          content: Text(AppLocalizations.of(context).address.updatedSuccess),
        ),
      );
  }

  Future<void> _addAddress(BuildContext context) async {
    final cubit = context.read<AddressSetupCubit>();
    final coordinates = await AppRouter.pushNamed<LocationCoordinates>(
      context,
      AppRoutes.mapPicker,
    );
    if (coordinates == null || !context.mounted) return;
    final created = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.addressDetails,
      arguments: coordinates,
    );
    if (created != true) return;
    // Create does not return the record, so re-read the persisted list.
    await cubit.load();
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.mutedText),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.mutedText,
                      ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(width: 240, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
