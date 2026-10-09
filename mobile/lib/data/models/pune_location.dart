import 'package:equatable/equatable.dart';

class PuneLocation extends Equatable {
  const PuneLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.landmarkNote,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? landmarkNote;

  @override
  List<Object?> get props => [name, latitude, longitude, landmarkNote];
}
