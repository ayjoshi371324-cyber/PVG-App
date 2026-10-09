import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Card displayed on the passenger's tracking screen once driver is en route,
/// showing their unique 4-digit curb-side boarding OTP and security instructions.
class PickupOtpCard extends StatelessWidget {
  const PickupOtpCard({
    super.key,
    required this.otpCode,
    this.passengerName = 'You',
  });

  final String otpCode;
  final String passengerName;

  String _formatSpacedOtp(String code) {
    final cleaned = code.replaceAll('#', '').replaceAll(' ', '');
    return cleaned.split('').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final formattedCode = _formatSpacedOtp(otpCode);

    return UberCard(
      variant: UberCardVariant.elevated,
      padding: const EdgeInsets.all(UberSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(UberSpacing.xs),
                decoration: const BoxDecoration(
                  color: UberColors.accentGreenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: UberColors.accentGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: UberSpacing.sm),
              Expanded(
                child: Text(
                  'Pickup OTP',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: UberColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: UberColors.canvasSoft,
                  borderRadius: UberRadii.pill,
                ),
                child: Text(
                  'Boarding Pin',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.sm),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UberSpacing.lg,
                vertical: UberSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: UberColors.canvasSoft,
                borderRadius: UberRadii.md,
                border: Border.all(color: UberColors.ink.withValues(alpha: 0.1)),
              ),
              child: Text(
                formattedCode,
                style: UberTypography.displayMd.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: UberColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: UberSpacing.xs),
          Text(
            'Share this 4-digit code with your driver only after they arrive at your pickup location.',
            textAlign: TextAlign.center,
            style: UberTypography.caption.copyWith(
              color: UberColors.body,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
