import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/address.dart';

class AddressListView extends StatelessWidget {
  const AddressListView({
    super.key,
    required this.addresses,
    this.onAddAddress,
  });

  final List<Address> addresses;
  final VoidCallback? onAddAddress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return CustomScrollView(
      key: const Key('address_populated_state'),
      slivers: [
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
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressTile(address: address);
            },
          ),
        ),
        // Keep primary action visible even when list is populated, but note
        // Step 2 does not implement editing/deleting — read-only list.
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
  const _AddressTile({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context).address;

    final labelText = l10n.labelFor(address.label.name);

    return Semantics(
      label: address.title,
      child: Card(
        key: Key('address_tile_${address.id}'),
        child: Padding(
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
        ),
      ),
    );
  }
}
