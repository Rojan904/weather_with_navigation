import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:weather_with_places/kaha_navigation_weather/models/place_location_model.dart';

class AutocompletePlacemarkManager {
  final String apiKey;
  final Ref ref;

  AutocompletePlacemarkManager({
    this.apiKey = 'AIzaSyDMgsnF4emRIM4eNXCuoIhRUVf7znAg1Vs',
    required this.ref,
  });

  Future<List>? fetchPlaceDetails(String name) async {
    // final point = const Point(27.7172, 85.3240);
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$name&components=country:np&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final placeDetails = json.decode(response.body);

      final results = placeDetails['predictions']
          .map((e) => {e['place_id']: e['description']})
          .toList();
      return results;
    } else {
      return [];
    }
  }

  Future<PlaceLocation?> getPlaceLatLng(id) async {
    try {
      if (id.toString().trim().isEmpty) return null;
      final requiredParams = 'place_id=$id&key=$apiKey';
      final queryParams = '$requiredParams&components=country:np';
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?$queryParams',
        ),
      );
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('result')) {
        final location = data['result']['geometry']['location'];
        final name = data['result']['formatted_address'] as String;
        return PlaceLocation(
          name: name,
          lat: location['lat'] as double,
          lng: location['lng'] as double,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final autoCompleteSuggestionsProvider =
    FutureProviderFamily<List?, String>((ref, a) {
  final data = ref.read(placemarkServiceProvider).fetchPlaceDetails(a);
  return data;
});

final placemarksDetailProvider = FutureProviderFamily<PlaceLocation?, String>(
  (ref, id) => ref.read(placemarkServiceProvider).getPlaceLatLng(id),
);

final placemarkServiceProvider =
    Provider((ref) => AutocompletePlacemarkManager(ref: ref));
