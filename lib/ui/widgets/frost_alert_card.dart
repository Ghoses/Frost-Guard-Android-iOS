import 'package:flutter/material.dart';
import 'package:frost_guard/core/constants/theme_constants.dart';
import 'package:frost_guard/core/utils/temperature_utils.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:provider/provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';

class FrostAlertCard extends StatelessWidget {
  final Location location;
  final WeatherData? weatherData;

  const FrostAlertCard({
    Key? key, 
    required this.location, 
    required this.weatherData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final temperatureUnit = settingsProvider.temperatureUnit;
    final threshold = settingsProvider.temperatureThreshold;
    
    // Überprüfen, ob die Daten geladen wurden
    if (weatherData == null || weatherData!.hourly.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: ThemeConstants.normalPadding),
      color: theme.brightness == Brightness.dark 
          ? ThemeConstants.frostWarningDarkColor 
          : ThemeConstants.frostWarningLightColor,
      child: Padding(
        padding: const EdgeInsets.all(ThemeConstants.normalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.ac_unit,
                  color: ThemeConstants.frostWarningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Frostwarnung!',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: ThemeConstants.frostWarningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Es wird heute Nacht in ${location.name} Frost geben. Die Temperatur wird voraussichtlich unter den eingestellten Schwellenwert von ${TemperatureUtils.formatTemperature(threshold, temperatureUnit)} fallen.',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bitte treffen Sie entsprechende Vorkehrungen zum Schutz von Pflanzen und temperaturempfindlichen Gegenständen.',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
