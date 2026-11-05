import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/address.dart';
import '../cubit/address_setup_cubit.dart';
import '../cubit/address_setup_state.dart';
import '../widgets/address_empty_view.dart';
import '../widgets/address_error_view.dart';
import '../widgets/address_list_view.dart';

/// Address Setup screen shown when an authenticated user has no addresses.
/// Also serves as the gate's empty/error/loading host.
/// [onAddAddress] is the future map-picker integration point — Step 2 does not
/// build a map/fake form.
class AddressSetupPage extends StatelessWidget {
  const AddressSetupPage({
    super.key,
    this.onAddAddress,
  });

  /// Called when the user taps “Add address”. In Step 2 this navigates to a
  /// placeholder that documents the next-phase map picker; no fake address is
  /// created here.
  final VoidCallback? onAddAddress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return BlocBuilder<AddressSetupCubit, AddressSetupState>(
      builder: (context, state) {
        return Scaffold(
          key: const Key('address_setup_page'),
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.setupTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.headingText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          body: SafeArea(
            child: _bodyFor(context, state, colors),
          ),
        );
      },
    );
  }

  Widget _bodyFor(
      BuildContext context, AddressSetupState state, AppSemanticColors colors) {
    switch (state.status) {
      case AddressSetupStatus.initial:
      case AddressSetupStatus.loading:
        return const Center(
          key: Key('address_setup_loading'),
          child: CircularProgressIndicator(),
        );
      case AddressSetupStatus.error:
        return AddressErrorView(
          failure: state.failure,
          onRetry: () => context.read<AddressSetupCubit>().retry(),
        );
      case AddressSetupStatus.empty:
        return AddressEmptyView(
          onAddAddress: onAddAddress ??
              () => _handleAddAddressPlaceholder(context),
        );
      case AddressSetupStatus.populated:
        return AddressListView(
          addresses: state.addresses,
          onAddAddress: onAddAddress ??
              () => _handleAddAddressPlaceholder(context),
        );
    }
  }

  void _handleAddAddressPlaceholder(BuildContext context) {
    // Step 3 integration point — do not build a fake map/form in Step 2.
    // This navigation is intentional and documented as the future picker entry.
    AppRouter.pushNamed(context, AppRoutes.mapPicker);
  }
}

/// Small helper for previews/tests to inject a known state without a cubit.
class AddressSetupContent extends StatelessWidget {
  const AddressSetupContent({
    super.key,
    required this.state,
    this.onRetry,
    this.onAddAddress,
  });

  final AddressSetupState state;
  final VoidCallback? onRetry;
  final VoidCallback? onAddAddress;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    switch (state.status) {
      case AddressSetupStatus.initial:
      case AddressSetupStatus.loading:
        return const Center(
          key: Key('address_setup_loading'),
          child: CircularProgressIndicator(),
        );
      case AddressSetupStatus.error:
        return AddressErrorView(
          failure: state.failure,
          onRetry: onRetry,
        );
      case AddressSetupStatus.empty:
        return AddressEmptyView(onAddAddress: onAddAddress);
      case AddressSetupStatus.populated:
        return AddressListView(
          addresses: state.addresses,
          onAddAddress: onAddAddress,
        );
    }
  }
}
