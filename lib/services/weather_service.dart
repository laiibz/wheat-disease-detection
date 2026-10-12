import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherData {
  final double temp;
  final int humidity;
  final String city;
  final String condition;

  WeatherData({
    required this.temp,
    required this.humidity,
    required this.city,
    required this.condition,
  });
}

class WeatherService {
  // IMPORTANT: The user should replace this with their own OpenWeatherMap API key
  static const String _apiKey = "a114b9c1acd76c4951d6f873e2d84379";

  Future<WeatherData?> fetchWeather() async {
    try {
      // 1. Get Location Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      // 2. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // 3. Get City Name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String cityName = placemarks.isNotEmpty ? placemarks[0].locality ?? "Unknown" : "Unknown";

      // 4. Fetch Weather Data
      // If no API key is provided, we return a mock for Pakistan's current season
      if (_apiKey.startsWith("REPLACE")) {
        return WeatherData(
          temp: 22.0,
          humidity: 65,
          city: cityName.isNotEmpty ? cityName : "Punjab, Pakistan",
          condition: "Cloudy",
        );
      }

      final url = "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric";
      final response = await http.get(Uri.parse(url));

      print("Weather API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData(
          temp: (data['main']['temp'] as num).toDouble(),
          humidity: data['main']['humidity'] as int,
          city: cityName,
          condition: data['weather'][0]['main'],
        );
      } else if (response.statusCode == 401) {
        print("API KEY ERROR: Your key might not be active yet. It takes ~30-60 mins.");
        // Return a mock so the user can still see the feature working
        return WeatherData(
          temp: 24.5,
          humidity: 58,
          city: "$cityName (Demo Mode)",
          condition: "Clear",
        );
      }
    } catch (e) {
      print("Weather Error: $e");
    }
    return null;
  }
}
