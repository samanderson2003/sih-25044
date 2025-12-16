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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFFFDE7), const Color(0xFFF1F8E9)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 1,
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
                      color: Color(0xFF2D5016),
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    weather!.location,
                    style: TextStyle(
                      color: const Color(0xFF2D5016).withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2D5016).withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2D5016)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: TextStyle(
                    color: const Color(0xFF2D5016).withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  child: label,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2D5016),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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
