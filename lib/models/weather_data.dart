class WeatherData {
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  WeatherData({
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final hourlyList = (json['hourly'] as List)
        .map((item) => HourlyWeather.fromJson(item))
        .toList();
    
    final dailyList = (json['daily'] as List)
        .map((item) => DailyWeather.fromJson(item))
        .toList();

    return WeatherData(
      hourly: hourlyList,
      daily: dailyList,
    );
  }
  
  // Hilfsmethode um einen leeren Datensatz für den Ladevorgang zu erstellen
  factory WeatherData.empty() {
    return WeatherData(
      hourly: [],
      daily: [],
    );
  }
}

class HourlyWeather {
  final int dt;
  final double temp;
  final int humidity;
  final List<WeatherCondition> weather;

  HourlyWeather({
    required this.dt,
    required this.temp,
    required this.humidity,
    required this.weather,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final weatherList = (json['weather'] as List)
        .map((item) => WeatherCondition.fromJson(item))
        .toList();

    return HourlyWeather(
      dt: json['dt'],
      temp: json['temp'].toDouble(),
      humidity: json['humidity'],
      weather: weatherList,
    );
  }
}

class DailyWeather {
  final int dt;
  final Temp temp;
  final List<WeatherCondition> weather;

  DailyWeather({
    required this.dt,
    required this.temp,
    required this.weather,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    final weatherList = (json['weather'] as List)
        .map((item) => WeatherCondition.fromJson(item))
        .toList();

    return DailyWeather(
      dt: json['dt'],
      temp: Temp.fromJson(json['temp']),
      weather: weatherList,
    );
  }
}

class Temp {
  final double day;
  final double min;
  final double max;
  final double night;

  Temp({
    required this.day,
    required this.min,
    required this.max,
    required this.night,
  });

  factory Temp.fromJson(Map<String, dynamic> json) {
    return Temp(
      day: json['day'].toDouble(),
      min: json['min'].toDouble(),
      max: json['max'].toDouble(),
      night: json['night'].toDouble(),
    );
  }
}

class WeatherCondition {
  final int id;
  final String main;
  final String description;
  final String icon;

  WeatherCondition({
    required this.id,
    required this.main,
    required this.description,
    required this.icon,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      id: json['id'],
      main: json['main'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}
