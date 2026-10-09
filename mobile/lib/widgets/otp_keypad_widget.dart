import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Interactive curb-side 4-digit PIN entry keypad used by drivers to verify
/// boarding passengers, enforcing 5-attempt lockout and demo bypass.
class OtpKeypadWidget extends StatelessWidget {
  const OtpKeypadWidget({
    super.key,
    required this.enteredOtp,
    required this.isVerified,
    required this.isLocked,
    this.errorMessage,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onClearPressed,
    required this.onBypassPressed,
    this.onManualOverride,
  });

  final String enteredOtp;
  final bool isVerified;
  final bool isLocked;
  final String? errorMessage;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onClearPressed;
  final VoidCallback onBypassPressed;
  final VoidCallback? onManualOverride;

  Widget _buildDigitBox(int index) {
    final digit = index < enteredOtp.length ? enteredOtp[index] : '';
    final isFilled = digit.isNotEmpty;

    return Container(
      width: 52,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isVerified
            ? UberColors.accentGreenSoft
            : (isFilled ? UberColors.canvasSoft : UberColors.canvas),
        borderRadius: UberRadii.md,
        border: Border.all(
          color: isVerified
              ? UberColors.accentGreen
              : (isFilled ? UberColors.ink : UberColors.canvasSoft),
          width: isFilled || isVerified ? 2.0 : 1.2,
        ),
      ),
      child: Text(
        digit,
        style: UberTypography.displaySm.copyWith(
          color: isVerified ? UberColors.accentGreen : UberColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: UberRadii.md,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor ?? UberColors.canvasSoft,
          borderRadius: UberRadii.md,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isVerified) {
      return UberCard(
        variant: UberCardVariant.elevated,
        padding: const EdgeInsets.all(UberSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: UberColors.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: UberSpacing.sm),
                Text(
                  'OTP Verified • Passenger Cleared to Board',
                  style: UberTypography.bodySmStrong.copyWith(
                    color: UberColors.accentGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UberSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildDigitBox(index),
              )),
            ),
          ],
        ),
      );
    }

    if (isLocked) {
      return UberCard(
        variant: UberCardVariant.elevated,
        padding: const EdgeInsets.all(UberSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(UberSpacing.sm),
              decoration: const BoxDecoration(
                color: UberColors.accentRedSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: UberColors.accentRed,
                size: 28,
              ),
            ),
            const SizedBox(height: UberSpacing.xs),
            Text(
              'Stop Locked (5 Failed Attempts)',
              style: UberTypography.bodyMdStrong.copyWith(
                color: UberColors.accentRed,
              ),
            ),
            const SizedBox(height: UberSpacing.xxs),
            Text(
              errorMessage ?? 'Consecutive OTP mismatch policy triggered. Manual override required.',
              textAlign: TextAlign.center,
              style: UberTypography.caption.copyWith(color: UberColors.body),
            ),
            const SizedBox(height: UberSpacing.md),
            Row(
              children: [
                if (onManualOverride != null)
                  Expanded(
                    child: PillButton(
                      label: 'Manual Override',
                      variant: PillButtonVariant.secondary,
                      size: PillButtonSize.medium,
                      icon: Icons.lock_open_rounded,
                      onPressed: onManualOverride,
                    ),
                  ),
                const SizedBox(width: UberSpacing.sm),
                Expanded(
                  child: PillButton(
                    label: 'Bypass OTP (Demo)',
                    variant: PillButtonVariant.primary,
                    size: PillButtonSize.medium,
                    icon: Icons.bolt_rounded,
                    onPressed: onBypassPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return UberCard(
      variant: UberCardVariant.tinted,
      padding: const EdgeInsets.all(UberSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Enter 4-Digit Pickup OTP',
                  style: UberTypography.bodySmStrong,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: onBypassPressed,
                icon: const Icon(Icons.bolt_rounded, size: 16, color: UberColors.accentOrange),
                label: Text(
                  'Bypass OTP (Demo)',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: UberColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.xs),

          // 4 Digit Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildDigitBox(index),
            )),
          ),

          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            const SizedBox(height: UberSpacing.xs),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: UberTypography.caption.copyWith(
                color: UberColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: UberSpacing.md),

          // Numeric Keypad 3x4
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildKeypadButton(
                    child: Text('1', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('1'),
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: Text('2', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('2'),
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: Text('3', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('3'),
                  )),
                ],
              ),
              const SizedBox(height: UberSpacing.xs),
              Row(
                children: [
                  Expanded(child: _buildKeypadButton(
                    child: Text('4', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('4'),
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: Text('5', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('5'),
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: Text('6', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('6'),
                  )),
                ],
              ),
              const SizedBox(height: UberSpacing.xs),
              Row(
                children: [
                  Expanded(child: _buildKeypadButton(
                    child: Text('7', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('7'),
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: Text('8', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('8'),
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: Text('9', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('9'),
                  )),
                ],
              ),
              const SizedBox(height: UberSpacing.xs),
              Row(
                children: [
                  Expanded(child: _buildKeypadButton(
                    child: Text('C', style: UberTypography.bodySmStrong.copyWith(color: UberColors.mute)),
                    onTap: onClearPressed ?? onDeletePressed,
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: Text('0', style: UberTypography.bodyLg),
                    onTap: () => onDigitPressed('0'),
                  )),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(child: _buildKeypadButton(
                    child: const Icon(Icons.backspace_outlined, size: 20, color: UberColors.ink),
                    onTap: onDeletePressed,
                  )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
