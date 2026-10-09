import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/role/role_cubit.dart';
import 'package:ridepool_app/blocs/role/role_state.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/views/driver/driver_home_view.dart';
import 'package:ridepool_app/views/ops/ops_home_view.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/widgets/role_switcher.dart';

class ShellView extends StatelessWidget {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleCubit, RoleState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: UberColors.canvas,
          appBar: AppBar(
            backgroundColor: UberColors.canvas,
            scrolledUnderElevation: 0,
            elevation: 0,
            titleSpacing: UberSpacing.lg,
            title: Row(
              children: [
                Text(
                  'RidePool',
                  style: UberTypography.displaySm.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: UberSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UberSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: UberColors.canvasSoft,
                    borderRadius: UberRadii.md,
                  ),
                  child: Text(
                    'AI',
                    style: UberTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: UberColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48.0),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: UberSpacing.lg,
                  right: UberSpacing.lg,
                  bottom: UberSpacing.sm,
                ),
                child: Center(
                  child: RoleSwitcher(
                    currentRole: state.currentRole,
                    onRoleChanged: (newRole) {
                      context.read<RoleCubit>().selectRole(newRole);
                    },
                  ),
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildRoleView(state.currentRole),
          ),
        );
      },
    );
  }

  Widget _buildRoleView(AppRole role) {
    switch (role) {
      case AppRole.passenger:
        return const PassengerHomeView(key: ValueKey('passenger_view'));
      case AppRole.driver:
        return const DriverHomeView(key: ValueKey('driver_view'));
      case AppRole.ops:
        return const OpsHomeView(key: ValueKey('ops_view'));
    }
  }
}
