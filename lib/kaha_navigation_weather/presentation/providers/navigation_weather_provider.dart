import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:weather_with_places/kaha_navigation_weather/models/weather_model.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/providers/autocomplete_placemark_manager.dart';

import '../../models/place_location_model.dart';

class NavigationWeatherManager {
  final Ref ref;

  NavigationWeatherManager({required this.ref});
  final apiKey = dotenv.env['WEATHER_API_KEY'];
  Future<WeatherModel?> fetchWeatherInfo(PlaceLocation location) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=${location.lat}&lon=${location.lng}&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherModel.fromJson(data);
    }
    return null;
  }

  Future<bool> selectPlace(
      String placeId, bool isSource, String description) async {
    try {
      final placemarkService = ref.read(placemarkServiceProvider);
      final location = await placemarkService.getPlaceLatLng(placeId);

      final locationData = location ?? _createFallbackLocation(description);

      final provider = isSource ? sourceDataProvider : destinationDataProvider;
      ref.read(provider.notifier).state = locationData;

      if (isSource && location != null) {
        ref.read(isSelectedFieldSourceProvider.notifier).state = false;
      }

      return location != null;
    } catch (error) {
      return false;
    }
  }

  PlaceLocation _createFallbackLocation(String description) {
    return PlaceLocation(
      name: description,
      lat: 27.7172, // Default coordinates for Kathmandu
      lng: 85.3240,
    );
  }

  // // Method to clear location data
  // void clearLocation(bool isSource) {
  //   final provider = isSource ? sourceDataProvider : destinationDataProvider;
  //   ref.read(provider.notifier).state = null;
  // }

  // // Toggle active field
  // void toggleActiveField(bool isSource) {
  //   ref.read(isSelectedFieldSourceProvider.notifier).state = isSource;
  // }
}

final navigationWeatherManagerProvider =
    Provider<NavigationWeatherManager>((ref) {
  return NavigationWeatherManager(ref: ref);
});

final isSelectedFieldSourceProvider = StateProvider<bool>((ref) => true);
final sourceDataProvider = StateProvider<PlaceLocation?>((ref) => null);
final destinationDataProvider = StateProvider<PlaceLocation?>((ref) => null);

final weatherInfoProvider =
    FutureProvider.family<WeatherModel?, PlaceLocation>((ref, location) {
  return ref.read(navigationWeatherManagerProvider).fetchWeatherInfo(location);
});
