import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/auth/auth_cubit.dart';
import 'package:ridepool_app/blocs/auth/auth_state.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';
import 'package:ridepool_app/widgets/pill_button.dart';

class DriverRegisterView extends StatefulWidget {
  const DriverRegisterView({super.key});

  @override
  State<DriverRegisterView> createState() => _DriverRegisterViewState();
}

class _DriverRegisterViewState extends State<DriverRegisterView> {
  final _nameController = TextEditingController(text: 'Santosh Tambe');
  final _emailController = TextEditingController(text: 'santosh.driver@ridepool.ai');
  final _phoneController = TextEditingController(text: '+91 98901 23456');
  final _passwordController = TextEditingController(text: 'password123');
  final _licensePlateController = TextEditingController(text: 'MH 12 RN 8842');
  final _driverLicenseController = TextEditingController(text: 'DL-MH12-2022-9842');
  final _formKey = GlobalKey<FormState>();

  VehicleTier _selectedTier = VehicleTier.car;

  @override
  void dispose() {
    _nameController.dispose;
    _emailController.dispose;
    _phoneController.dispose;
    _passwordController.dispose;
    _licensePlateController.dispose;
    _driverLicenseController.dispose;
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final req = RegisterDriverRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        vehicleTier: _selectedTier,
        licensePlate: _licensePlateController.text.trim(),
        driverLicenseNumber: _driverLicenseController.text.trim(),
      );
      context.read<AuthCubit>().registerDriver(req);
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
            'Driver Onboarding',
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
                    'Partner with RidePool AI',
                    style: UberTypography.displaySm.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: UberSpacing.xs),
                  Text(
                    'Higher vehicle utilization with guaranteed transparent payouts',
                    style: UberTypography.bodySm.copyWith(color: UberColors.body),
                  ),
                  const SizedBox(height: UberSpacing.lg),

                  // Personal Information
                  Text(
                    'Driver Credentials',
                    style: UberTypography.bodySmStrong,
                  ),
                  const SizedBox(height: UberSpacing.sm),

                  TextFormField(
                    key: const Key('driver_name_input'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Legal Name',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter legal name' : null,
                  ),
                  const SizedBox(height: UberSpacing.sm),

                  TextFormField(
                    key: const Key('driver_email_input'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) =>
                        val == null || !val.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: UberSpacing.sm),

                  TextFormField(
                    key: const Key('driver_phone_input'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: UberSpacing.sm),

                  TextFormField(
                    key: const Key('driver_password_input'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Account Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) =>
                        val == null || val.length < 6 ? 'Min 6 characters' : null,
                  ),

                  const SizedBox(height: UberSpacing.lg),

                  // Vehicle Details
                  Text(
                    'Vehicle Onboarding',
                    style: UberTypography.bodySmStrong,
                  ),
                  const SizedBox(height: UberSpacing.sm),

                  // Vehicle Tier Selection Chips
                  Text(
                    'Select Vehicle Tier:',
                    style: UberTypography.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: UberSpacing.xs),
                  Row(
                    children: VehicleTier.values.map((tier) {
                      final isSelected = _selectedTier == tier;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ChoiceChip(
                            key: Key('driver_tier_chip_${tier.name}'),
                            label: Text(
                              tier.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? UberColors.onPrimary : UberColors.ink,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: UberColors.ink,
                            backgroundColor: UberColors.canvasSoft,
                            onSelected: (val) {
                              if (val) setState(() => _selectedTier = tier);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: UberSpacing.sm),

                  // License Plate Number
                  TextFormField(
                    key: const Key('driver_plate_input'),
                    controller: _licensePlateController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Vehicle License Plate (e.g. MH 12 RN 8842)',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter license plate' : null,
                  ),
                  const SizedBox(height: UberSpacing.sm),

                  // Driver License Number
                  TextFormField(
                    key: const Key('driver_license_input'),
                    controller: _driverLicenseController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Driver License Number (e.g. DL-MH12-2022-9842)',
                      prefixIcon: const Icon(Icons.card_membership_outlined),
                      border: OutlineInputBorder(borderRadius: UberRadii.md),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter driver license number'
                        : null,
                  ),

                  const SizedBox(height: UberSpacing.xl),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return PillButton(
                        key: const Key('register_driver_submit_button'),
                        label: isLoading ? 'Submitting Application...' : 'Onboard Driver & Vehicle',
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
