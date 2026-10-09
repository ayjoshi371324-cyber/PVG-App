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

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (landmarkNote != null) 'landmarkNote': landmarkNote,
      };

  factory PuneLocation.fromJson(Map<String, dynamic> json) => PuneLocation(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        landmarkNote: json['landmarkNote'] as String?,
      );

  @override
  List<Object?> get props => [name, latitude, longitude, landmarkNote];
}
