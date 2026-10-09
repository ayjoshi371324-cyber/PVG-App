import 'package:flutter/material.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

class LandmarkChips extends StatelessWidget {
  const LandmarkChips({
    super.key,
    required this.onLandmarkSelected,
    this.selectedLocation,
    this.landmarks = PuneLandmarks.all,
  });

  final ValueChanged<PuneLocation> onLandmarkSelected;
  final PuneLocation? selectedLocation;
  final List<PuneLocation> landmarks;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: landmarks.map((loc) {
          final isSelected = selectedLocation == loc;

          return Padding(
            padding: const EdgeInsets.only(right: UberSpacing.sm),
            child: Material(
              color: isSelected ? UberColors.primary : UberColors.canvasSoft,
              borderRadius: UberRadii.pill,
              child: InkWell(
                onTap: () => onLandmarkSelected(loc),
                borderRadius: UberRadii.pill,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UberSpacing.md,
                    vertical: UberSpacing.xs + 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_outlined,
                        size: 14.0,
                        color: isSelected ? UberColors.onPrimary : UberColors.ink,
                      ),
                      const SizedBox(width: UberSpacing.xs),
                      Text(
                        loc.name,
                        style: UberTypography.bodySmStrong.copyWith(
                          color: isSelected ? UberColors.onPrimary : UberColors.ink,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
