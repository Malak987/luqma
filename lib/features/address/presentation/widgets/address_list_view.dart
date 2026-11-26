import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/address.dart';

/// The saved-address list, shared by the post-login setup screen and the Home
/// address sheet.
///
/// Selection and editing are optional: the setup screen shows a read-only list,
/// while the Home sheet passes [onSelect] and [onEdit] to make the same tiles
/// interactive. Keys `address_populated_state`, `address_tile_<id>` and
/// `address_add_button_populated` are the existing test contract.
class AddressListView extends StatelessWidget {
  const AddressListView({
    super.key,
    required this.addresses,
    this.onAddAddress,
    this.onSelect,
    this.onEdit,
    this.selectedId,
    this.header,
  });

  final List<Address> addresses;
  final VoidCallback? onAddAddress;
  final ValueChanged<Address>? onSelect;
  final ValueChanged<Address>? onEdit;

  /// The address currently used for delivery, highlighted in the list.
  final String? selectedId;

  /// Optional widget shown above the title (used by the Home sheet).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return CustomScrollView(
      key: const Key('address_populated_state'),
      slivers: [
        if (header != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
            sliver: SliverToBoxAdapter(child: header),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.myAddressesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList.separated(
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressTile(
                address: address,
                selected: address.id == selectedId,
                onTap: onSelect == null ? null : () => onSelect!(address),
                onEdit: onEdit == null ? null : () => onEdit!(address),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: AppButton(
              key: const Key('address_add_button_populated'),
              text: l10n.addAddress,
              onPressed: onAddAddress,
              icon: const Icon(Icons.add_location_alt_outlined),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    this.onTap,
    this.onEdit,
  });

  final Address address;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context).address;
    final labelText = l10n.labelFor(address.label.name);

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.smallRadius,
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  labelText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.headingText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.18),
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: Text(
                    l10n.defaultBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.headingText,
                    ),
                  ),
                ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: Text(
                    l10n.selectedBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (onEdit != null)
                TextButton.icon(
                  key: Key('address_edit_${address.id}'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.editAction),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.link,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                    minimumSize: const Size(0, 40),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            address.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.district}, ${address.city}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            address.details,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );

    return Semantics(
      label: address.title,
      selected: selected,
      button: onTap != null,
      child: Material(
        key: Key('address_tile_${address.id}'),
        color: colors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
