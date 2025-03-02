import 'package:flutter/material.dart';
import 'package:frost_guard/core/constants/app_constants.dart';
import 'package:frost_guard/core/constants/theme_constants.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/core/utils/temperature_utils.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';
import 'package:frost_guard/providers/weather_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(ThemeConstants.normalPadding),
            children: [
              _buildSectionHeader(context, 'Anzeige'),
              _buildDarkModeSwitch(context, settingsProvider),
              _buildTemperatureUnitSelector(context, settingsProvider),
              
              const SizedBox(height: ThemeConstants.largePadding),
              _buildSectionHeader(context, 'Frostwarnungen'),
              _buildThresholdSlider(context, settingsProvider),
              _buildNotificationSwitch(context, settingsProvider),
              
              if (settingsProvider.notificationsEnabled)
                _buildCheckTimeSelector(context, settingsProvider),
              
              const SizedBox(height: ThemeConstants.largePadding),
              _buildSectionHeader(context, 'Über'),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildDarkModeSwitch(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: SwitchListTile(
        title: const Text('Dunkles Design'),
        subtitle: const Text('Dunkles Farbschema für die App verwenden'),
        value: settingsProvider.isDarkMode,
        onChanged: (value) => settingsProvider.setDarkMode(value),
      ),
    );
  }

  Widget _buildTemperatureUnitSelector(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConstants.normalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Temperatureinheit'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Celsius (°C)'),
                    value: AppConstants.temperatureUnitCelsius,
                    groupValue: settingsProvider.temperatureUnit,
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.setTemperatureUnit(value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Fahrenheit (°F)'),
                    value: AppConstants.temperatureUnitFahrenheit,
                    groupValue: settingsProvider.temperatureUnit,
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.setTemperatureUnit(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSlider(BuildContext context, SettingsProvider settingsProvider) {
    final temperatureUnit = settingsProvider.temperatureUnit;
    
    // Umrechnungsbereiche je nach Temperatureinheit
    final double minValue = temperatureUnit == AppConstants.temperatureUnitCelsius ? -5.0 : 23.0;
    final double maxValue = temperatureUnit == AppConstants.temperatureUnitCelsius ? 10.0 : 50.0;
    
    // Aktuelle Schwelle in der richtigen Einheit
    double currentThreshold = settingsProvider.temperatureThreshold;
    if (temperatureUnit == AppConstants.temperatureUnitFahrenheit) {
      currentThreshold = TemperatureUtils.celsiusToFahrenheit(currentThreshold);
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConstants.normalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frostwarnschwelle: ${TemperatureUtils.formatTemperature(currentThreshold, temperatureUnit)}',
            ),
            const SizedBox(height: 8),
            Slider(
              min: minValue,
              max: maxValue,
              divisions: ((maxValue - minValue) * 2).toInt(), // 0.5°C/F Schritte
              value: currentThreshold,
              label: TemperatureUtils.formatTemperature(currentThreshold, temperatureUnit),
              onChanged: (value) {
                // Umrechnung zurück zu Celsius für die Speicherung
                double celsiusValue = value;
                if (temperatureUnit == AppConstants.temperatureUnitFahrenheit) {
                  celsiusValue = TemperatureUtils.fahrenheitToCelsius(value);
                }
                settingsProvider.setTemperatureThreshold(celsiusValue);
              },
              onChangeEnd: (value) {
                // Wenn der Slider losgelassen wird, aktualisiere die Wetterdaten
                _updateWeatherDataWithNewThreshold(context, settingsProvider);
              },
            ),
            const Text(
              'Legen Sie fest, bei welcher Temperatur Sie gewarnt werden möchten. '
              'Die App warnt Sie, wenn die Temperatur in der Nacht unter diesen Schwellenwert fällt.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Aktualisiert die Wetterdaten mit dem neuen Schwellenwert
  void _updateWeatherDataWithNewThreshold(BuildContext context, SettingsProvider settingsProvider) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    
    // Nur aktualisieren, wenn Standorte vorhanden sind
    if (locationProvider.locations.isNotEmpty) {
      weatherProvider.updateAllForecasts(
        locationProvider.locations,
        threshold: settingsProvider.temperatureThreshold,
        notificationsEnabled: settingsProvider.notificationsEnabled,
      );
    }
  }

  Widget _buildNotificationSwitch(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Benachrichtigungen'),
            subtitle: const Text('Erhalten Sie Benachrichtigungen bei Frostgefahr'),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) => settingsProvider.setNotificationsEnabled(value),
          ),
          if (settingsProvider.notificationsEnabled)
            Padding(
              padding: const EdgeInsets.only(
                left: ThemeConstants.normalPadding,
                right: ThemeConstants.normalPadding,
                bottom: ThemeConstants.normalPadding,
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Überprüfe Berechtigungen vor dem Senden
                    final bool hasPermission = await NotificationService().checkAndRequestNotificationPermissions();
                    
                    if (!hasPermission) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Benachrichtigungen wurden nicht zugelassen. Bitte aktiviere sie in den Geräteeinstellungen.'),
                          duration: Duration(seconds: 4),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Sende Test-Benachrichtigung
                    await NotificationService().showTestNotification();
                    
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test-Benachrichtigung gesendet'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler: ${e.toString()}'),
                        duration: const Duration(seconds: 4),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications),
                label: const Text('Test Benachrichtigung'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckTimeSelector(BuildContext context, SettingsProvider settingsProvider) {
    // Formatierung der aktuellen Überprüfungszeit
    final hour = settingsProvider.checkHour;
    final minute = settingsProvider.checkMinute;
    final formattedTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    
    return Card(
      child: ListTile(
        title: const Text('Überprüfungszeit'),
        subtitle: Text('Die App überprüft jeden Tag um $formattedTime Uhr, ob Frost zu erwarten ist'),
        trailing: const Icon(Icons.access_time),
        onTap: () => _showTimePicker(context, settingsProvider),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, SettingsProvider settingsProvider) async {
    final initialTime = TimeOfDay(
      hour: settingsProvider.checkHour, 
      minute: settingsProvider.checkMinute
    );
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (selectedTime != null) {
      settingsProvider.setCheckTime(selectedTime.hour, selectedTime.minute);
    }
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConstants.normalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frost Guard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diese App hilft Ihnen, Ihre Pflanzen und temperaturempfindliche Gegenstände vor Frostschäden zu schützen, indem sie Sie rechtzeitig über zu erwartenden Frost informiert.',
            ),
            const SizedBox(height: 16),
            const Text(
              '''Wetterdaten werden über die OpenWeatherMap API bereitgestellt.
              Scripted by Ghoses 2025 - www.ape-x.net // www.github.com/ghoses''',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
