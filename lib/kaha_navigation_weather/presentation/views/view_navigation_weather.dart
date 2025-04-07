import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/providers/autocomplete_placemark_manager.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/providers/navigation_weather_provider.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/widgets/location_field.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/widgets/suggestion_list.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/widgets/weather_card_widget.dart';

class ViewNavigationWeather extends ConsumerStatefulWidget {
  const ViewNavigationWeather({super.key});

  @override
  ConsumerState<ViewNavigationWeather> createState() =>
      _ViewNavigationWeatherState();
}

class _ViewNavigationWeatherState extends ConsumerState<ViewNavigationWeather> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String _activeQuery = '';

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _handleQueryChanged(String query) {
    setState(() {
      _activeQuery = query;
    });
  }

  void _handleSuggestionSelected(String placeId, String description) {
    final isSource = ref.read(isSelectedFieldSourceProvider);
    final controller = isSource ? _sourceController : _destinationController;
    controller.text = description;
    setState(() => _activeQuery = '');
    ref
        .read(navigationWeatherManagerProvider)
        .selectPlace(placeId, isSource, description);
  }

  @override
  Widget build(BuildContext context) {
    final sourceLocation = ref.watch(sourceDataProvider);
    final destinationLocation = ref.watch(destinationDataProvider);
    final suggestionsAsync = _activeQuery.isNotEmpty
        ? ref.watch(autoCompleteSuggestionsProvider(_activeQuery))
        : null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Weather & Navigation'),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _activeQuery = '');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationField(
                  controller: _sourceController,
                  labelText: 'Source Location',
                  prefixIcon: Icons.location_on_rounded,
                  isSource: true,
                  onQueryChanged: _handleQueryChanged,
                ),
                const SizedBox(height: 16),
                LocationField(
                  controller: _destinationController,
                  labelText: 'Destination Location',
                  prefixIcon: Icons.flag,
                  isSource: false,
                  onQueryChanged: _handleQueryChanged,
                ),
                const SizedBox(height: 16),
                if (_activeQuery.isNotEmpty)
                  SuggestionList(
                    suggestionsAsync: suggestionsAsync,
                    onSelected: _handleSuggestionSelected,
                  ),
                if (sourceLocation != null || destinationLocation != null)
                  const WeatherCardWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
