import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/auth/auth_cubit.dart';
import 'package:ridepool_app/blocs/auth/auth_state.dart';
import 'package:ridepool_app/blocs/role/role_cubit.dart';
import 'package:ridepool_app/blocs/role/role_state.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/repositories/ride_pool_repository.dart';
import 'package:ridepool_app/views/auth/auth_welcome_view.dart';
import 'package:ridepool_app/views/driver/driver_home_view.dart';
import 'package:ridepool_app/views/ops/ops_home_view.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/widgets/role_switcher.dart';

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  bool _inspectorMode = false;
  bool _isLiveBackend =
      DualModeRidePoolRepository.instance.mode == RepositoryMode.liveBackend;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authCubit = context.read<AuthCubit>();
        final authState = authCubit.state;
        if (authState is Authenticated) {
          _syncRoleFromAuth(authState.user.role);
        }
      } catch (_) {}
    });
  }

  void _syncRoleFromAuth(UserRole role) {
    AppRole targetRole;
    switch (role) {
      case UserRole.passenger:
        targetRole = AppRole.passenger;
        break;
      case UserRole.driver:
        targetRole = AppRole.driver;
        break;
      case UserRole.ops:
        targetRole = AppRole.ops;
        break;
    }
    if (context.read<RoleCubit>().state.currentRole != targetRole) {
      context.read<RoleCubit>().selectRole(targetRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthCubit? authCubit;
    try {
      authCubit = context.watch<AuthCubit>();
    } catch (_) {
      authCubit = null;
    }

    final authState = authCubit?.state;

    final content = BlocBuilder<RoleCubit, RoleState>(
      builder: (context, roleState) {
          // If unauthenticated and not in inspector mode, show welcome screen
          if (authState is Unauthenticated && !_inspectorMode) {
            return const Scaffold(
              backgroundColor: UberColors.canvas,
              body: AuthWelcomeView(key: ValueKey('auth_welcome_view')),
            );
          }

          // Effective role follows user role selection or inspector override
          final effectiveRole = _inspectorMode ? AppRole.ops : roleState.currentRole;

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
            actions: [
              // Dual-Mode Repository Toggle: Live Backend vs Offline Simulation
              Padding(
                padding: const EdgeInsets.only(right: UberSpacing.xs),
                child: ActionChip(
                  key: const Key('header_backend_mode_toggle'),
                  avatar: Icon(
                    _isLiveBackend
                        ? Icons.cloud_done_rounded
                        : Icons.offline_pin_rounded,
                    size: 14,
                    color: _isLiveBackend
                        ? UberColors.accentGreen
                        : UberColors.body,
                  ),
                  label: Text(
                    _isLiveBackend ? 'Live Backend' : 'Offline Sim',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isLiveBackend
                          ? UberColors.accentGreen
                          : UberColors.body,
                    ),
                  ),
                  backgroundColor: _isLiveBackend
                      ? UberColors.accentGreenSoft
                      : UberColors.canvasSoft,
                  side: BorderSide(
                    color: _isLiveBackend
                        ? UberColors.accentGreen
                        : Colors.transparent,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLiveBackend = !_isLiveBackend;
                      DualModeRidePoolRepository.instance.setMode(
                        _isLiveBackend
                            ? RepositoryMode.liveBackend
                            : RepositoryMode.offlineSimulation,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isLiveBackend
                              ? 'Connected to Live FastAPI Backend (http://127.0.0.1:8000)'
                              : 'Switched to Offline Simulation Mode',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              // Header Demo/Inspector Switch: Instant access to Ops Fleet Console
              Padding(
                padding: const EdgeInsets.only(right: UberSpacing.md),
                child: ActionChip(
                  key: const Key('header_inspector_switch'),
                  avatar: Icon(
                    _inspectorMode ? Icons.close_rounded : Icons.insights_rounded,
                    size: 14,
                    color: _inspectorMode ? UberColors.accentOrange : UberColors.ink,
                  ),
                  label: Text(
                    _inspectorMode ? 'Exit Ops' : 'Ops Console',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _inspectorMode ? UberColors.accentOrange : UberColors.ink,
                    ),
                  ),
                  backgroundColor:
                      _inspectorMode ? UberColors.accentOrangeSoft : UberColors.canvasSoft,
                  side: BorderSide(
                    color: _inspectorMode ? UberColors.accentOrange : Colors.transparent,
                  ),
                  onPressed: () {
                    setState(() {
                      _inspectorMode = !_inspectorMode;
                    });
                  },
                ),
              ),
              if (authState is Authenticated)
                IconButton(
                  key: const Key('auth_logout_button'),
                  tooltip: 'Sign Out (${authState.user.email})',
                  icon: const Icon(Icons.logout_rounded, size: 20, color: UberColors.body),
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                  },
                ),
            ],
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
                    currentRole: _inspectorMode ? AppRole.ops : effectiveRole,
                    onRoleChanged: (newRole) {
                      if (_inspectorMode) {
                        setState(() => _inspectorMode = false);
                      }
                      context.read<RoleCubit>().selectRole(newRole);
                      try {
                        final cubit = context.read<AuthCubit>();
                        if (cubit.state is Authenticated) {
                          UserRole targetUserRole;
                          switch (newRole) {
                            case AppRole.passenger:
                              targetUserRole = UserRole.passenger;
                              break;
                            case AppRole.driver:
                              targetUserRole = UserRole.driver;
                              break;
                            case AppRole.ops:
                              targetUserRole = UserRole.ops;
                              break;
                          }
                          cubit.loginAsDemo(targetUserRole);
                        }
                      } catch (_) {}
                    },
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              if (_inspectorMode)
                Container(
                  width: double.infinity,
                  color: UberColors.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: UberSpacing.md,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            size: 14,
                            color: UberColors.accentGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Inspector Mode Active • Session Preserved',
                            style: UberTypography.caption.copyWith(
                              color: UberColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _inspectorMode = false);
                        },
                        child: Text(
                          'Return to Session',
                          style: UberTypography.caption.copyWith(
                            color: UberColors.accentGreen,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _inspectorMode
                      ? const OpsHomeView(key: ValueKey('ops_inspector_view'))
                      : _buildRoleView(effectiveRole),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (authCubit != null) {
      return BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            _syncRoleFromAuth(state.user.role);
          }
        },
        child: content,
      );
    }

    return content;
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
