import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weather_service.dart';
import '../utils/risk_calculator.dart';
import '../theme/app_theme.dart';
import '../services/language_service.dart';

class WeatherRiskWidget extends StatefulWidget {
  const WeatherRiskWidget({super.key});

  @override
  State<WeatherRiskWidget> createState() => _WeatherRiskWidgetState();
}

class _WeatherRiskWidgetState extends State<WeatherRiskWidget> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weather;
  List<DiseaseRisk>? _risks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final weather = await _weatherService.fetchWeather();
    if (weather != null) {
      final risks = RiskCalculator.calculateRisks(weather.temp, weather.humidity);
      if (mounted) {
        setState(() {
          _weather = weather;
          _risks = risks;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    if (_weather == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 30),
            const SizedBox(height: 10),
            Text(
              lang.translate('weather_unavailable'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              lang.translate('check_gps_internet'),
              style: theme.textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadData();
              },
              child: Text(lang.translate('retry'), style: TextStyle(color: theme.colorScheme.primary)),
            )
          ],
        ),
      );
    }

    final highestRisk = _risks?.first;
    final bool isOffSeason = highestRisk?.name == "Off-Season";
    Color riskColor = isOffSeason ? Colors.greenAccent : _getRiskColor(highestRisk?.riskLevel ?? 0.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                      Icon(Icons.location_on, color: theme.colorScheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(_weather!.city, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_weather!.temp.toStringAsFixed(1)}°C",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isDark ? Colors.white : theme.colorScheme.primary,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_weather!.condition, style: theme.textTheme.bodyLarge),
                  Text("${lang.translate('humidity')}: ${_weather!.humidity}%", style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          Divider(height: 30, color: isDark ? Colors.white10 : Colors.black12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOffSeason ? Icons.calendar_today_rounded : Icons.warning_amber_rounded, 
                  color: riskColor
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOffSeason 
                        ? lang.translate('off_season') 
                        : "${lang.translate('current_disease_risk')}: ${((highestRisk?.riskLevel ?? 0) * 100).toInt()}%",
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      isOffSeason 
                        ? lang.translate('off_season_desc')
                        : "${lang.translate('highest_threat')}: ${lang.translate(highestRisk?.name ?? 'Low')}",
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
              if (!isOffSeason)
                TextButton(
                  onPressed: () => _showDetailedRisks(context, lang),
                  child: Text(lang.translate('details'), style: TextStyle(color: theme.colorScheme.primary)),
                )
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double level) {
    if (level > 0.7) return Colors.redAccent;
    if (level > 0.4) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  void _showDetailedRisks(BuildContext context, LanguageService lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBotanicalGreen,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.translate('climate_risks_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
              const SizedBox(height: 20),
              ...?_risks?.map((risk) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    CircularProgressIndicator(
                      value: risk.riskLevel,
                      backgroundColor: Colors.white10,
                      color: _getRiskColor(risk.riskLevel),
                      strokeWidth: 4,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.translate(risk.name), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(risk.advice, style: const TextStyle(fontSize: 12, color: AppTheme.sageGreen)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
