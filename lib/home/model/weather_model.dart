class Weather {
  final double temperature; // in Celsius
  final double humidity; // in percentage
  final double rainfallProbability; // in percentage
  final String condition; // sunny, cloudy, rainy, etc.
  final double windSpeed; // in km/h
  final DateTime timestamp;
  final String location;

  Weather({
    required this.temperature,
    required this.humidity,
    required this.rainfallProbability,
    required this.condition,
    required this.windSpeed,
    required this.timestamp,
    required this.location,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      rainfallProbability: (json['rainfallProbability'] ?? 0).toDouble(),
      condition: json['condition'] ?? 'unknown',
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'rainfallProbability': rainfallProbability,
      'condition': condition,
      'windSpeed': windSpeed,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
    };
  }
}

class WeatherAlert {
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;

  WeatherAlert({
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

enum AlertSeverity { low, medium, high, critical }

extension AlertSeverityExtension on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.critical:
        return 'CRITICAL';
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.low:
        return 'LOW';
    }
  }
}
