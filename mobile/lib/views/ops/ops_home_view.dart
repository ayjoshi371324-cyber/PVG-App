import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ridepool_app/blocs/ops/ops_cubit.dart';
import 'package:ridepool_app/blocs/ops/ops_state.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/cabin_occupancy_bar.dart';
import 'package:ridepool_app/widgets/comparative_benchmark_card.dart';
import 'package:ridepool_app/widgets/detour_guarantee_inspector.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/pune_map_widget.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class OpsHomeView extends StatelessWidget {
  const OpsHomeView({super.key, this.cubit});

  final OpsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    OpsCubit? existingCubit;
    try {
      existingCubit = cubit ?? context.read<OpsCubit>();
    } catch (_) {
      existingCubit = null;
    }

    if (existingCubit != null) {
      return BlocProvider<OpsCubit>.value(
        value: existingCubit,
        child: const _OpsHomeContent(),
      );
    }

    return BlocProvider<OpsCubit>(
      create: (_) => OpsCubit(),
      child: const _OpsHomeContent(),
    );
  }
}

class _OpsHomeContent extends StatelessWidget {
  const _OpsHomeContent();

  List<Marker> _buildFleetMarkers(BuildContext context, List<FleetVehicle> vehicles, String? selectedId) {
    return vehicles.map((v) {
      final isSelected = v.id == selectedId;
      Color statusColor;
      IconData icon;

      switch (v.status) {
        case FleetVehicleStatus.idle:
          statusColor = UberColors.body;
          icon = Icons.pause_circle_outline_rounded;
          break;
        case FleetVehicleStatus.pickingUp:
          statusColor = UberColors.accentOrange;
          icon = Icons.person_pin_circle_rounded;
          break;
        case FleetVehicleStatus.inPool:
          statusColor = UberColors.ink;
          icon = Icons.electric_car_rounded;
          break;
      }

      return Marker(
        point: v.currentLocation.toLatLng(),
        width: 104,
        height: 44,
        child: GestureDetector(
          onTap: () {
            context.read<OpsCubit>().selectVehicle(v.id);
          },
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? UberColors.ink : UberColors.canvas,
                borderRadius: UberRadii.pill,
                border: Border.all(
                  color: isSelected ? UberColors.accentGreen : statusColor,
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? UberColors.onPrimary : statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    v.id,
                    style: UberTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? UberColors.onPrimary : UberColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OpsCubit, OpsState>(
      builder: (context, state) {
        final fleetMarkers = _buildFleetMarkers(
          context,
          state.vehicles,
          state.selectedVehicleId,
        );

        return Scaffold(
          backgroundColor: UberColors.canvas,
          body: Stack(
            children: [
              // Fleet overview map
              Positioned.fill(
                child: PuneMapWidget(
                  extraMarkers: fleetMarkers,
                ),
              ),

              // Upper Floating Status Header
              Positioned(
                top: UberSpacing.md,
                left: UberSpacing.lg,
                right: UberSpacing.lg,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: UberSpacing.sm,
                  runSpacing: UberSpacing.xs,
                  children: [
                    MetricBadge(
                      label: 'Fleet Active',
                      value: '${state.activeFleetCount}/${state.totalFleetCount}',
                      icon: Icons.electric_car_rounded,
                      variant: MetricBadgeVariant.neutral,
                      compact: true,
                    ),
                    MetricBadge(
                      label: 'Detour',
                      value: '100% Compliant',
                      icon: Icons.verified_user_rounded,
                      variant: MetricBadgeVariant.success,
                      compact: true,
                    ),
                    MetricBadge(
                      label: 'Batches',
                      value: '#${state.totalCompletedBatches}',
                      icon: Icons.auto_awesome_rounded,
                      variant: MetricBadgeVariant.dark,
                      compact: true,
                    ),
                  ],
                ),
              ),

              // Operations Bottom Sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomDrawerSheet(
                  title: 'Dynamic Intake Queue',
                  subtitle:
                      '${state.pendingDemand.length} pending requests awaiting batch optimization',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Control actions row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: PillButton(
                                  key: const Key('ops_trigger_batch_button'),
                                  label: 'Trigger Batch Now',
                                  size: PillButtonSize.large,
                                  variant: PillButtonVariant.primary,
                                  icon: Icons.play_arrow_rounded,
                                  onPressed: () {
                                    context.read<OpsCubit>().triggerBatchOptimization();
                                  },
                                ),
                              ),
                              const SizedBox(width: UberSpacing.sm),
                              Expanded(
                                flex: 2,
                                child: PillButton(
                                  key: const Key('ops_inject_demand_button'),
                                  label: 'Inject +3',
                                  size: PillButtonSize.large,
                                  variant: PillButtonVariant.secondary,
                                  icon: Icons.add_rounded,
                                  onPressed: () {
                                    context.read<OpsCubit>().injectSyntheticDemand(count: 3);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: UberSpacing.md),

                          // Selected Vehicle Detail Card (if any selected)
                          if (state.selectedVehicle != null) ...[
                            UberCard(
                              variant: UberCardVariant.elevated,
                              padding: const EdgeInsets.all(UberSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${state.selectedVehicle!.id} • ${state.selectedVehicle!.name}',
                                            style: UberTypography.bodySmStrong,
                                          ),
                                          Text(
                                            '${state.selectedVehicle!.licensePlate} • ${state.selectedVehicle!.currentLocation.name}',
                                            style: UberTypography.caption,
                                          ),
                                          if (state.selectedVehicle!.assignedRouteName != null)
                                            Text(
                                              state.selectedVehicle!.assignedRouteName!,
                                              style: UberTypography.caption.copyWith(
                                                color: UberColors.accentGreen,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          MetricBadge(
                                            label: '',
                                            value: state.selectedVehicle!.statusLabel,
                                            variant: state.selectedVehicle!.isInPool
                                                ? MetricBadgeVariant.dark
                                                : (state.selectedVehicle!.isPickingUp
                                                    ? MetricBadgeVariant.warning
                                                    : MetricBadgeVariant.neutral),
                                            compact: true,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${state.selectedVehicle!.currentOccupancy}/${state.selectedVehicle!.maxCapacity} Seats',
                                            style: UberTypography.caption,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: UberSpacing.sm),
                                  CabinOccupancyBar(
                                    maxCapacity: state.selectedVehicle!.maxCapacity,
                                    onboardSeats: state.selectedVehicle!.onboardSeats,
                                    reservedSeats: state.selectedVehicle!.reservedSeats,
                                    heldSeats: state.selectedVehicle!.heldSeats,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: UberSpacing.md),
                          ],

                          // Active Fleet Cabin Occupancy Overview
                          UberCard(
                            variant: UberCardVariant.standard,
                            padding: const EdgeInsets.all(UberSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.airline_seat_recline_normal_rounded,
                                          size: 16,
                                          color: UberColors.ink,
                                        ),
                                        const SizedBox(width: UberSpacing.xs),
                                        Text(
                                          'Fleet Cabin Occupancy',
                                          style: UberTypography.bodySmStrong,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${state.activeFleetCount} active',
                                      style: UberTypography.caption.copyWith(
                                        color: UberColors.body,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: UberSpacing.sm),
                                ...state.vehicles.map((v) {
                                  final isSelected = v.id == state.selectedVehicleId;
                                  return InkWell(
                                    key: Key('fleet_vehicle_${v.id}'),
                                    onTap: () => context.read<OpsCubit>().selectVehicle(v.id),
                                    borderRadius: UberRadii.md,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: UberSpacing.xs),
                                      padding: const EdgeInsets.all(UberSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: isSelected ? UberColors.canvasSoft : Colors.transparent,
                                        borderRadius: UberRadii.md,
                                        border: isSelected ? Border.all(color: UberColors.ink) : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${v.id} (${v.name})',
                                                style: UberTypography.caption.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: UberColors.ink,
                                                ),
                                              ),
                                              Text(
                                                v.statusLabel,
                                                style: UberTypography.caption.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: v.isInPool
                                                      ? UberColors.accentGreen
                                                      : (v.isPickingUp ? UberColors.accentOrange : UberColors.body),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          CabinOccupancyBar(
                                            maxCapacity: v.maxCapacity,
                                            onboardSeats: v.onboardSeats,
                                            reservedSeats: v.reservedSeats,
                                            heldSeats: v.heldSeats,
                                            height: 6.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: UberSpacing.md),

                          // Comparative Benchmarks Card
                          ComparativeBenchmarkCard(
                            benchmark: state.benchmark,
                          ),

                          const SizedBox(height: UberSpacing.md),

                          // Detour Guarantees Inspector
                          DetourGuaranteeInspector(
                            records: state.activeDetourRecords,
                          ),

                          const SizedBox(height: UberSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
