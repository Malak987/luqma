import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../cubit/address_setup_cubit.dart';
import '../cubit/address_setup_state.dart';
import 'address_setup_page.dart';

/// Post-authentication gate that ensures an address exists before exposing Home.
/// While loading, Home is NOT shown. Errors are surfaced with retry; failures
/// are never treated as empty. Duplicate loads are prevented by the cubit.
class AuthenticatedAddressGate extends StatelessWidget {
  const AuthenticatedAddressGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressSetupCubit>(
      create: (_) => sl<AddressSetupCubit>()..load(),
      child: const _GateView(),
    );
  }
}

class _GateView extends StatelessWidget {
  const _GateView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressSetupCubit, AddressSetupState>(
      builder: (context, state) {
        switch (state.status) {
          case AddressSetupStatus.initial:
          case AddressSetupStatus.loading:
            return const _GateLoading();
          case AddressSetupStatus.error:
            // Show the same AddressSetupPage error UI but gate-owned retry.
            return const AddressSetupPage();
          case AddressSetupStatus.empty:
            return const AddressSetupPage();
          case AddressSetupStatus.populated:
            return const _AuthenticatedHome();
        }
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Scaffold(
      key: const Key('address_gate_loading'),
      backgroundColor: colors.background,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AuthenticatedHome extends StatelessWidget {
  const _AuthenticatedHome();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (_) => sl<HomeCubit>(),
      child: const HomePage(),
    );
  }
}
