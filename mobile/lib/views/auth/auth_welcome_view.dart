import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/auth/auth_cubit.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/views/auth/driver_register_view.dart';
import 'package:ridepool_app/views/auth/login_view.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class AuthWelcomeView extends StatelessWidget {
  const AuthWelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UberColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: UberSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              // Brand Hero
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: UberColors.ink,
                    borderRadius: UberRadii.xl,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.electric_car_rounded,
                      size: 36,
                      color: UberColors.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: UberSpacing.md),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RouteMates',
                      style: UberTypography.displayLg.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: UberSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              ),
              const SizedBox(height: UberSpacing.xs),
              Center(
                child: Text(
                  'Algorithmic Carpooling for Pune',
                  style: UberTypography.bodyMd.copyWith(
                    color: UberColors.body,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Primary Actions
              PillButton(
                key: const Key('auth_passenger_signin_button'),
                label: 'Continue as Passenger',
                size: PillButtonSize.large,
                variant: PillButtonVariant.primary,
                icon: Icons.person_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginView(defaultRole: UserRole.passenger),
                    ),
                  );
                },
              ),
              const SizedBox(height: UberSpacing.sm),
              PillButton(
                key: const Key('auth_driver_onboard_button'),
                label: 'Driver Onboarding & Sign In',
                size: PillButtonSize.large,
                variant: PillButtonVariant.secondary,
                icon: Icons.sports_motorsports_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DriverRegisterView(),
                    ),
                  );
                },
              ),

              const SizedBox(height: UberSpacing.lg),

              // 1-Tap Demo / Evaluator Presets
              UberCard(
                variant: UberCardVariant.elevated,
                padding: const EdgeInsets.all(UberSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: UberColors.accentOrange,
                        ),
                        const SizedBox(width: UberSpacing.xs),
                        Text(
                          'Evaluator Instant Demo Sign-In',
                          style: UberTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: UberColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UberSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('demo_login_passenger_button'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: UberColors.ink,
                              side: const BorderSide(color: UberColors.canvasSoft),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              context.read<AuthCubit>().loginAsDemo(UserRole.passenger);
                            },
                            child: const Text('Passenger', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: UberSpacing.xs),
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('demo_login_driver_button'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: UberColors.ink,
                              side: const BorderSide(color: UberColors.canvasSoft),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              context.read<AuthCubit>().loginAsDemo(UserRole.driver);
                            },
                            child: const Text('Driver', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: UberSpacing.xs),
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('demo_login_ops_button'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: UberColors.ink,
                              side: const BorderSide(color: UberColors.canvasSoft),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              context.read<AuthCubit>().loginAsDemo(UserRole.ops);
                            },
                            child: const Text('Ops Fleet', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: UberSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
