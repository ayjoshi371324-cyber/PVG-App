import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/auth/auth_cubit.dart';
import 'package:ridepool_app/blocs/auth/auth_state.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/views/auth/passenger_register_view.dart';
import 'package:ridepool_app/widgets/pill_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    this.defaultRole = UserRole.passenger,
  });

  final UserRole defaultRole;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.defaultRole == UserRole.driver) {
      _emailController.text = 'driver@ridepool.ai';
    } else {
      _emailController.text = 'passenger@ridepool.ai';
    }
    _passwordController.text = 'password123';
  }

  @override
  void dispose() {
    _emailController.dispose;
    _passwordController.dispose;
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: UberColors.accentRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: UberColors.canvas,
        appBar: AppBar(
          backgroundColor: UberColors.canvas,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: UberColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Sign In',
            style: UberTypography.bodyMdStrong.copyWith(color: UberColors.ink),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UberSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome back',
                    style: UberTypography.displaySm.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: UberSpacing.xs),
                  Text(
                    'Sign in to access your RidePool account',
                    style: UberTypography.bodySm.copyWith(color: UberColors.body),
                  ),
                  const SizedBox(height: UberSpacing.xl),

                  // Email
                  TextFormField(
                    key: const Key('login_email_input'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: UberRadii.md,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || !val.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: UberSpacing.md),

                  // Password
                  TextFormField(
                    key: const Key('login_password_input'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: UberRadii.md,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: UberSpacing.xl),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return PillButton(
                        key: const Key('login_submit_button'),
                        label: isLoading ? 'Signing In...' : 'Sign In',
                        size: PillButtonSize.large,
                        variant: PillButtonVariant.primary,
                        onPressed: isLoading ? null : _submit,
                      );
                    },
                  ),

                  const SizedBox(height: UberSpacing.md),

                  Center(
                    child: TextButton(
                      key: const Key('goto_register_button'),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const PassengerRegisterView(),
                          ),
                        );
                      },
                      child: Text(
                        "Don't have an account? Register as Passenger",
                        style: UberTypography.bodySmStrong.copyWith(
                          color: UberColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
