import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_with_places/kaha_navigation_weather/models/weather_model.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/providers/navigation_weather_provider.dart';
import 'package:weather_with_places/utils/extension.dart';

class WeatherCardWidget extends ConsumerStatefulWidget {
  const WeatherCardWidget({super.key});

  @override
  ConsumerState<WeatherCardWidget> createState() => _WeatherCardWidgetState();
}

class _WeatherCardWidgetState extends ConsumerState<WeatherCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showSourceWeather = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLocation() =>
      setState(() => _showSourceWeather = !_showSourceWeather);

  @override
  Widget build(BuildContext context) {
    final sourceLocation = ref.watch(sourceDataProvider);
    final destinationLocation = ref.watch(destinationDataProvider);
    final hasSource = sourceLocation != null;
    final hasDestination = destinationLocation != null;

    if (!hasSource && !hasDestination) {
      if (_animationController.isCompleted) _animationController.reset();
      return const SizedBox.shrink();
    }

    if (_showSourceWeather && !hasSource && hasDestination) {
      _showSourceWeather = false;
    } else if (!_showSourceWeather && !hasDestination && hasSource) {
      _showSourceWeather = true;
    }

    final sourceWeatherAsync =
        hasSource ? ref.watch(weatherInfoProvider(sourceLocation)) : null;
    final destinationWeatherAsync = hasDestination
        ? ref.watch(weatherInfoProvider(destinationLocation))
        : null;

    if (!_animationController.isCompleted) _animationController.forward();

    if (hasSource && hasDestination) {
      return _showSourceWeather
          ? _buildWeatherCard(sourceLocation.name, sourceWeatherAsync, true,
              true, destinationLocation.name, destinationWeatherAsync, true)
          : _buildWeatherCard(destinationLocation.name, destinationWeatherAsync,
              false, true, sourceLocation.name, sourceWeatherAsync, true);
    } else if (hasSource) {
      return _buildWeatherCard(sourceLocation.name, sourceWeatherAsync, true,
          false, null, null, false);
    } else {
      return _buildWeatherCard(destinationLocation!.name,
          destinationWeatherAsync, false, false, null, null, false);
    }
  }

  Widget _buildWeatherCard(
    String location,
    AsyncValue<WeatherModel?>? weatherAsync,
    bool isSource,
    bool hasSecondary,
    String? secondaryLocation,
    AsyncValue<WeatherModel?>? secondaryWeatherAsync,
    bool canToggle,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCirc,
        child: FadeTransition(
          opacity: _animation,
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationHeader(location, isSource, canToggle),
                  const SizedBox(height: 16),
                  _buildPrimaryWeatherSection(weatherAsync),
                  if (hasSecondary &&
                      secondaryLocation != null &&
                      secondaryWeatherAsync != null)
                    _buildSecondaryLocation(
                        secondaryLocation, secondaryWeatherAsync, isSource),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader(String location, bool isSource, bool canToggle) {
    return GestureDetector(
      onTap: canToggle ? _toggleLocation : null,
      child: Row(
        children: [
          Icon(
            isSource ? Icons.location_on_rounded : Icons.flag,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canToggle)
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildPrimaryWeatherSection(AsyncValue<WeatherModel?>? weatherAsync) {
    return weatherAsync?.when(
          data: (data) => data == null
              ? const Center(child: Text('No weather data available'))
              : _buildWeatherContent(data),
          loading: () => const Center(
              child: CircularProgressIndicator(
            strokeWidth: 2,
          )),
          error: (error, _) => const Center(
            child: Text('Error loading weather data',
                style: TextStyle(color: Colors.red)),
          ),
        ) ??
        const SizedBox.shrink();
  }

  Widget _buildSecondaryLocation(String location,
      AsyncValue<WeatherModel?>? weatherAsync, bool isPrimarySource) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _toggleLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(!isPrimarySource ? Icons.location_on_rounded : Icons.flag,
                    size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 8),
                _buildCompactSecondaryWeather(weatherAsync),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSecondaryWeather(
      AsyncValue<WeatherModel?>? weatherAsync) {
    return weatherAsync?.when(
          data: (weather) => weather == null
              ? const Text('N/A')
              : Row(
                  children: [
                    const Icon(Icons.cloud, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${weather.temperature.round()}°",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_upward,
                        size: 14, color: Colors.grey),
                  ],
                ),
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Text('Error',
              style: TextStyle(color: Colors.red, fontSize: 12)),
        ) ??
        const Text('N/A');
  }

  Widget _buildWeatherContent(WeatherModel weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${weather.temperature.round()}°",
                    style: const TextStyle(
                        fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                _getWeatherIcon(weather.mainCondition, weather.icon),
              ],
            ),
            Text(
              weather.description.toString().capitalizeFirst(),
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(Icons.water_drop, Colors.blue,
                  "${weather.humidity}%", "Humidity"),
              _buildWeatherDetail(Icons.air, Colors.blueGrey,
                  "${weather.windSpeed} m/s", "Wind"),
              weather.rain != null
                  ? _buildWeatherDetail(Icons.umbrella, Colors.indigo,
                      "${weather.rain!['1h'] ?? 0} mm", "Rain")
                  : _buildWeatherDetail(Icons.thermostat, Colors.orange,
                      "${weather.feelsLike.round()}°", "Feels like"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(
      IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _getWeatherIcon(String condition, String iconCode,
      {double size = 50}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        "https://openweathermap.org/img/wn/$iconCode@2x.png",
        fit: BoxFit.contain,
      ),
    );
  }
}
