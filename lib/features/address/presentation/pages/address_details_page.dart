import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../../domain/entities/address_label.dart';
import '../cubit/address_form_cubit.dart';
import '../cubit/address_form_state.dart';

/// Polished address details screen after map confirmation.
/// Preserves the selected [LocationCoordinates] and submits via `POST /api/Address/Create`.
class AddressDetailsPage extends StatelessWidget {
  const AddressDetailsPage({
    super.key,
    required this.coordinates,
    this.onAddressCreated,
  });

  final LocationCoordinates coordinates;
  final VoidCallback? onAddressCreated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressFormCubit>(
      create: (_) => sl<AddressFormCubit>(param1: coordinates),
      child: _AddressDetailsView(
        coordinates: coordinates,
        onAddressCreated: onAddressCreated,
      ),
    );
  }
}

class _AddressDetailsView extends StatefulWidget {
  const _AddressDetailsView({
    required this.coordinates,
    this.onAddressCreated,
  });

  final LocationCoordinates coordinates;
  final VoidCallback? onAddressCreated;

  @override
  State<_AddressDetailsView> createState() => _AddressDetailsViewState();
}

class _AddressDetailsViewState extends State<_AddressDetailsView> {
  late final TextEditingController _titleController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _districtController = TextEditingController();
    _cityController = TextEditingController();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return BlocListener<AddressFormCubit, AddressFormState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == AddressFormStatus.success,
      listener: (ctx, state) {
        if (widget.onAddressCreated != null) {
          widget.onAddressCreated!();
        } else {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        key: const Key('address_details_page'),
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.headingText),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            l10n.detailsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.headingText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<AddressFormCubit, AddressFormState>(
            builder: (context, state) {
              return SingleChildScrollView(
                key: const Key('address_details_scroll'),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtitle
                        Text(
                          l10n.detailsSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.mutedText,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Selected location summary
                        _LocationSummaryCard(coordinates: state.coordinates),
                        const SizedBox(height: AppSpacing.lg),

                        // Label selector
                        _LabelSelector(
                          selected: state.label,
                          onSelected: (label) =>
                              context.read<AddressFormCubit>().updateLabel(label),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Form fields
                        _FormFields(
                          titleController: _titleController,
                          districtController: _districtController,
                          cityController: _cityController,
                          detailsController: _detailsController,
                          state: state,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Validation hint
                        if (state.hasValidationErrors)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              l10n.detailsValidationMessage,
                              key: const Key('address_details_validation_error'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Error banner
                        if (state.isFailure && state.failure != null)
                          Container(
                            key: const Key('address_details_error'),
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.elevatedSurface,
                              borderRadius: AppRadius.mediumRadius,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  l10n.detailsErrorTitle,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                if (state.failure?.debugMessage != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    state.failure!.debugMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                AppButton(
                                  key: const Key('address_details_error_retry'),
                                  text: l10n.detailsErrorRetry,
                                  onPressed: () =>
                                      context.read<AddressFormCubit>().retrySubmit(),
                                ),
                              ],
                            ),
                          ),

                        // Submit button
                        AppButton(
                          key: const Key('address_details_submit'),
                          text: state.isSubmitting
                              ? l10n.detailsSubmitting
                              : l10n.detailsSubmit,
                          loading: state.isSubmitting,
                          enabled: !state.isSubmitting,
                          onPressed: state.isSubmitting
                              ? null
                              : () => context.read<AddressFormCubit>().submit(),
                          semanticLabel: l10n.detailsSubmit,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Accessibility hint
                        Semantics(
                          header: true,
                          child: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LocationSummaryCard extends StatelessWidget {
  const _LocationSummaryCard({required this.coordinates});

  final LocationCoordinates coordinates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Container(
      key: const Key('address_details_location_summary'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.place_outlined,
              color: colors.primary,
              semanticLabel: l10n.detailsLocationSectionTitle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.detailsLocationSectionTitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.headingText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.detailsLocationCoordinates(
                    coordinates.latitude,
                    coordinates.longitude,
                  ),
                  key: const Key('address_details_coordinates'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.detailsLocationHint,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelSelector extends StatelessWidget {
  const _LabelSelector({required this.selected, required this.onSelected});

  final AddressLabel selected;
  final ValueChanged<AddressLabel> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.detailsLabelSectionTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.detailsLabelHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _LabelChip(
              label: AddressLabel.home,
              text: l10n.homeLabel,
              icon: Icons.home_outlined,
              isSelected: selected == AddressLabel.home,
              onSelected: onSelected,
            ),
            _LabelChip(
              label: AddressLabel.work,
              text: l10n.workLabel,
              icon: Icons.work_outline,
              isSelected: selected == AddressLabel.work,
              onSelected: onSelected,
            ),
            _LabelChip(
              label: AddressLabel.other,
              text: l10n.otherLabel,
              icon: Icons.place_outlined,
              isSelected: selected == AddressLabel.other,
              onSelected: onSelected,
            ),
          ],
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.text,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  final AddressLabel label;
  final String text;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<AddressLabel> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Semantics(
      button: true,
      selected: isSelected,
      child: FilterChip(
        key: Key('address_label_${label.name}'),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.onPrimary : colors.mutedText,
            ),
            const SizedBox(width: 6),
            Text(text),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(label),
        backgroundColor: colors.surface,
        selectedColor: colors.primary,
        checkmarkColor: colors.onPrimary,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? colors.onPrimary : colors.bodyText,
              fontWeight: FontWeight.w600,
            ),
        side: BorderSide(color: isSelected ? colors.primary : colors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

class _FormFields extends StatelessWidget {
  const _FormFields({
    required this.titleController,
    required this.districtController,
    required this.cityController,
    required this.detailsController,
    required this.state,
  });

  final TextEditingController titleController;
  final TextEditingController districtController;
  final TextEditingController cityController;
  final TextEditingController detailsController;
  final AddressFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final validation = AppLocalizations.of(context);

    String? errorFor(ValidationErrorKey? key) =>
        validation.validationMessage(key) ?? l10n.detailsRequiredField;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('address_details_title_field'),
          controller: titleController,
          labelText: l10n.detailsFieldTitleLabel,
          hintText: l10n.detailsFieldTitleHint,
          textInputAction: TextInputAction.next,
          onChanged: (v) => context.read<AddressFormCubit>().updateTitle(v),
          errorText: state.titleError != null ? errorFor(state.titleError) : null,
          semanticLabel: l10n.detailsFieldTitleLabel,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('address_details_district_field'),
          controller: districtController,
          labelText: l10n.detailsFieldDistrictLabel,
          hintText: l10n.detailsFieldDistrictHint,
          textInputAction: TextInputAction.next,
          onChanged: (v) => context.read<AddressFormCubit>().updateDistrict(v),
          errorText: state.districtError != null ? errorFor(state.districtError) : null,
          semanticLabel: l10n.detailsFieldDistrictLabel,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('address_details_city_field'),
          controller: cityController,
          labelText: l10n.detailsFieldCityLabel,
          hintText: l10n.detailsFieldCityHint,
          textInputAction: TextInputAction.next,
          onChanged: (v) => context.read<AddressFormCubit>().updateCity(v),
          errorText: state.cityError != null ? errorFor(state.cityError) : null,
          semanticLabel: l10n.detailsFieldCityLabel,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('address_details_details_field'),
          controller: detailsController,
          labelText: l10n.detailsFieldDetailsLabel,
          hintText: l10n.detailsFieldDetailsHint,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          minLines: 2,
          onChanged: (v) => context.read<AddressFormCubit>().updateDetails(v),
          errorText: state.detailsError != null ? errorFor(state.detailsError) : null,
          semanticLabel: l10n.detailsFieldDetailsLabel,
        ),
      ],
    );
  }
}
