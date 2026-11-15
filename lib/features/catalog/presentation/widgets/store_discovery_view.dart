import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/catalog_route_arguments.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/store.dart';
import '../cubit/store_discovery_cubit.dart';
import '../cubit/store_discovery_state.dart';
import 'discovery_filters.dart';
import 'discovery_header.dart';
import 'discovery_search_bar.dart';
import 'store_results_slivers.dart';

/// The whole "browse stores" screen, shared by the Restaurants tab and the
/// per-category route. It needs a [StoreDiscoveryCubit] above it and only
/// differs by the copy it is given.
class StoreDiscoveryView extends StatefulWidget {
  const StoreDiscoveryView({
    required this.title,
    required this.searchHint,
    required this.sectionTitle,
    required this.sectionHint,
    super.key,
  });

  final String title;
  final String searchHint;
  final String sectionTitle;
  final String sectionHint;

  @override
  State<StoreDiscoveryView> createState() => _StoreDiscoveryViewState();
}

class _StoreDiscoveryViewState extends State<StoreDiscoveryView> {
  final ScrollController _scrollController = ScrollController();
  static const double _nextPageThreshold = 360;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadNextPage);
    unawaited(context.read<StoreDiscoveryCubit>().load());
  }

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions ||
        _scrollController.position.userScrollDirection !=
            ScrollDirection.reverse ||
        _scrollController.position.extentAfter > _nextPageThreshold) return;
    unawaited(context.read<StoreDiscoveryCubit>().loadNextPage());
  }

  void _resetScroll() {
    if (!_scrollController.hasClients || _scrollController.offset == 0) return;
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _scrollController.jumpTo(0);
    } else {
      unawaited(_scrollController.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadNextPage);
    _scrollController.dispose();
    super.dispose();
  }

  void _openStore(Store store) {
    AppRouter.pushNamed<void>(context, AppRoutes.storeDetails,
        arguments: StoreDetailsArguments(store: store));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final canGoBack = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: BlocListener<StoreDiscoveryCubit, StoreDiscoveryState>(
              listenWhen: (previous, current) =>
                  previous.selectedCuisineId != current.selectedCuisineId ||
                  previous.openNowOnly != current.openNowOnly,
              listener: (_, __) => _resetScroll(),
              child: CustomScrollView(
                key: const PageStorageKey('store_discovery_scroll'),
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: DiscoveryHeader(
                        title: widget.title, showBack: canGoBack),
                  ),
                  SliverToBoxAdapter(
                    child: DiscoverySearchBar(hintText: widget.searchHint),
                  ),
                  const SliverToBoxAdapter(child: DiscoveryFilterBar()),
                  const SliverToBoxAdapter(child: DiscoveryCuisineFilter()),
                  SliverToBoxAdapter(
                    child: DiscoverySectionHeader(
                      title: widget.sectionTitle,
                      subtitle: widget.sectionHint,
                    ),
                  ),
                  StoreResultsSliver(onStoreTap: _openStore),
                  const StorePaginationSliver(),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
