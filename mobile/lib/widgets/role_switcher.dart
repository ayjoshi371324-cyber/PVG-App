import 'package:flutter/material.dart';
import 'package:ridepool_app/blocs/role/role_state.dart';
import 'package:ridepool_app/core/theme.dart';

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
  });

  final AppRole currentRole;
  final ValueChanged<AppRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UberColors.canvasSoft,
        borderRadius: UberRadii.pill,
      ),
      padding: const EdgeInsets.all(4.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: AppRole.values.map((role) {
          final isSelected = currentRole == role;

          return GestureDetector(
            onTap: () => onRoleChanged(role),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: UberSpacing.lg,
                vertical: UberSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? UberColors.primary : Colors.transparent,
                borderRadius: UberRadii.pill,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? role.activeIcon : role.icon,
                    size: 16.0,
                    color: isSelected ? UberColors.onPrimary : UberColors.body,
                  ),
                  const SizedBox(width: UberSpacing.xs),
                  Text(
                    role.label,
                    style: UberTypography.bodySmStrong.copyWith(
                      color: isSelected ? UberColors.onPrimary : UberColors.body,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }
}
