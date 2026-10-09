import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

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

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [name, latitude, longitude, landmarkNote];
}
