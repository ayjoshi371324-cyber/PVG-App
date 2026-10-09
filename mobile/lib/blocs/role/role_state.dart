import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AppRole {
  passenger(
    label: 'Passenger',
    description: 'Book rides, dynamic batch matching & Shapley receipts',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
  driver(
    label: 'Driver',
    description: 'Ordered stop manifest, passenger boarding & occupancy',
    icon: Icons.drive_eta_outlined,
    activeIcon: Icons.drive_eta_rounded,
  ),
  ops(
    label: 'Operations',
    description: 'Fleet map, batch runner, detour audits & synthetic traffic',
    icon: Icons.hub_outlined,
    activeIcon: Icons.hub_rounded,
  );

  const AppRole({
    required this.label,
    required this.description,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String description;
  final IconData icon;
  final IconData activeIcon;
}

class RoleState extends Equatable {
  const RoleState({
    required this.currentRole,
    this.previousRole,
  });

  final AppRole currentRole;
  final AppRole? previousRole;

  RoleState copyWith({
    AppRole? currentRole,
    AppRole? previousRole,
  }) {
    return RoleState(
      currentRole: currentRole ?? this.currentRole,
      previousRole: previousRole ?? this.previousRole,
    );
  }

  @override
  List<Object?> get props => [currentRole, previousRole];
}
