// Model classes
class PlaceLocation {
  final String name;
  final double lat;
  final double lng;

  PlaceLocation({
    required this.name,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
    };
  }

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      name: json['name'] as String,
      lat: json['lat'] as double,
      lng: json['lng'] as double,
    );
  }
}
