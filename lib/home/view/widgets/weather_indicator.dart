import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../model/weather_model.dart';
import '../../../widgets/translated_text.dart';

class WeatherIndicator extends StatelessWidget {
  final Weather? weather;

  const WeatherIndicator({super.key, this.weather});

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF2D5016).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main temperature and location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather!.temperature.toStringAsFixed(0)}°',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TranslatedText(
                    weather!.location,
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Weather animation
              _getWeatherAnimation(weather!.condition),
            ],
          ),

          const SizedBox(height: 16),

          // Weather details grid - only Soil temp and Humidity
          Row(
            children: [
              Expanded(
                child: _buildWeatherDetailCard(
                  Icons.thermostat_outlined,
                  TranslatedText('Soil temp'),
                  '+${(weather!.temperature - 5).toStringAsFixed(0)} C',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeatherDetailCard(
                  Icons.water_drop_outlined,
                  TranslatedText('Humidity'),
                  '${weather!.humidity.toInt()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailCard(IconData icon, Widget label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFBBDEFB).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF90CAF9).withOpacity(0.3),
                  Color(0xFFE3F2FD).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1976D2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: const TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  child: label,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getWeatherAnimation(String condition) {
    String animationPath;

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        animationPath = 'assets/sunny.json';
        break;
      case 'cloudy':
      case 'partly cloudy':
        animationPath = 'assets/Cloudy.json';
        break;
      case 'rainy':
      case 'rain':
        animationPath = 'assets/Rainy.json';
        break;
      default:
        animationPath = 'assets/Cloudy.json';
    }

    return SizedBox(
      width: 100,
      height: 100,
      child: Lottie.asset(animationPath, fit: BoxFit.contain),
    );
  }
}
