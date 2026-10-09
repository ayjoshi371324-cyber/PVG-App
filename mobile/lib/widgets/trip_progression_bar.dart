import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';

/// Visual vertical timeline progress indicator showing upcoming pickup and dropoff milestones.
class TripProgressionBar extends StatelessWidget {
  const TripProgressionBar({
    super.key,
    required this.waypoints,
  });

  final List<TripWaypoint> waypoints;

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < waypoints.length; i++) ...[
          _buildMilestoneRow(
            waypoint: waypoints[i],
            isLast: i == waypoints.length - 1,
          ),
        ],
      ],
    );
  }

  Widget _buildMilestoneRow({
    required TripWaypoint waypoint,
    required bool isLast,
  }) {
    final isCompleted = waypoint.status == WaypointStatus.completed;
    final isCurrent = waypoint.status == WaypointStatus.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column (icon/circle + vertical connector)
          Column(
            children: [
              _buildIndicator(waypoint),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.0,
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    color: isCompleted
                        ? UberColors.accentGreen
                        : UberColors.canvasSoft,
                  ),
                ),
            ],
          ),
          const SizedBox(width: UberSpacing.md),

          // Milestone details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0.0 : UberSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          waypoint.label,
                          style: isCurrent
                              ? UberTypography.bodyMdStrong
                              : UberTypography.bodySm.copyWith(
                                  color: isCompleted
                                      ? UberColors.mute
                                      : UberColors.body,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: UberSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: UberColors.ink,
                            borderRadius: UberRadii.pill,
                          ),
                          child: Text(
                            'NEXT STOP',
                            style: UberTypography.caption.copyWith(
                              color: UberColors.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(waypoint),
                    style: UberTypography.caption.copyWith(
                      color: isCompleted
                          ? UberColors.accentGreen
                          : (isCurrent ? UberColors.ink : UberColors.mute),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(TripWaypoint waypoint) {
    switch (waypoint.status) {
      case WaypointStatus.completed:
        return const Icon(
          Icons.check_circle_rounded,
          color: UberColors.accentGreen,
          size: 20,
        );
      case WaypointStatus.current:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: UberColors.ink,
            shape: BoxShape.circle,
            border: Border.all(
              color: UberColors.canvas,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: UberColors.onPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case WaypointStatus.pending:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: UberColors.canvas,
            shape: BoxShape.circle,
            border: Border.all(
              color: UberColors.mute,
              width: 2.0,
            ),
          ),
        );
    }
  }

  String _getSubtitle(TripWaypoint waypoint) {
    switch (waypoint.status) {
      case WaypointStatus.completed:
        return 'Stop completed';
      case WaypointStatus.current:
        return 'Approaching stop (~${waypoint.estimatedMinutes} min away)';
      case WaypointStatus.pending:
        return 'Estimated arrival in ~${waypoint.estimatedMinutes} min';
    }
  }
}
