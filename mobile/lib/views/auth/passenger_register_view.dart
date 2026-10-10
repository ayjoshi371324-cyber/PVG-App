import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/auth/auth_cubit.dart';
import 'package:ridepool_app/blocs/auth/auth_state.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/widgets/pill_button.dart';

class PassengerRegisterView extends StatefulWidget {
  const PassengerRegisterView({super.key});

  @override
  State<PassengerRegisterView> createState() => _PassengerRegisterViewState();
}

class _PassengerRegisterViewState extends State<PassengerRegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose;
    _emailController.dispose;
    _phoneController.dispose;
    _passwordController.dispose;
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final req = RegisterPassengerRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );
      context.read<AuthCubit>().registerPassenger(req);
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
            'Passenger Registration',
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
                    'Create your account',
                    style: UberTypography.displaySm.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: UberSpacing.xs),
                  Text(
                    'Join shared commuting with guaranteed fair fares in Pune',
                    style: UberTypography.bodySm.copyWith(color: UberColors.body),
                  ),
                  const SizedBox(height: UberSpacing.xl),

                  // Full Name
                  TextFormField(
                    key: const Key('register_name_input'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: UberSpacing.md),

                  // Email
                  TextFormField(
                    key: const Key('register_email_input'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) {
                      if (val == null || !val.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: UberSpacing.md),

                  // Phone
                  TextFormField(
                    key: const Key('register_phone_input'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                  ),
                  const SizedBox(height: UberSpacing.md),

                  // Password
                  TextFormField(
                    key: const Key('register_password_input'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
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
                        key: const Key('register_passenger_submit_button'),
                        label: isLoading ? 'Creating Account...' : 'Register',
                        size: PillButtonSize.large,
                        variant: PillButtonVariant.primary,
                        onPressed: isLoading ? null : _submit,
                      );
                    },
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
