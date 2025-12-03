import 'package:flutter/material.dart';
import '../../model/weather_model.dart';

class WeatherIndicator extends StatelessWidget {
  final Weather? weather;

  const WeatherIndicator({super.key, this.weather});

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2D5016), // Primary dark green
            Color(0xFF3D6B23), // Lighter green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        weather!.location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${weather!.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    weather!.condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _getWeatherIcon(weather!.condition),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white54),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                Icons.water_drop,
                '${weather!.humidity.toInt()}%',
                'Humidity',
              ),
              _buildWeatherDetail(
                Icons.cloud,
                '${weather!.rainfallProbability.toInt()}%',
                'Rain Chance',
              ),
              _buildWeatherDetail(
                Icons.air,
                '${weather!.windSpeed.toInt()} km/h',
                'Wind',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData icon;
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        icon = Icons.wb_sunny;
        break;
      case 'cloudy':
      case 'partly cloudy':
        icon = Icons.wb_cloudy;
        break;
      case 'rainy':
      case 'rain':
        icon = Icons.water_drop;
        break;
      case 'stormy':
        icon = Icons.thunderstorm;
        break;
      default:
        icon = Icons.wb_cloudy;
    }

    return Icon(icon, size: 80, color: Colors.white.withOpacity(0.8));
  }
}
