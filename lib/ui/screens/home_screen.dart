import 'package:flutter/material.dart';
import 'package:frost_guard/core/constants/theme_constants.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';
import 'package:frost_guard/providers/weather_provider.dart';
import 'package:frost_guard/ui/screens/settings_screen.dart';
import 'package:frost_guard/ui/widgets/add_location_dialog.dart';
import 'package:frost_guard/ui/widgets/weather_card.dart';
import 'package:provider/provider.dart';
import 'package:frost_guard/core/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      _isInitialized = true;
      
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.loadLocations();
      
      // Wetterdaten aktualisieren, wenn Standorte geladen wurden
      if (locationProvider.locations.isNotEmpty) {
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        
        await weatherProvider.updateAllForecasts(
          locationProvider.locations,
          threshold: settingsProvider.temperatureThreshold,
          notificationsEnabled: settingsProvider.notificationsEnabled,
        );
      }
    }
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddLocationDialog(),
    );
  }
  
  Future<void> _refreshData() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    
    await locationProvider.loadLocations();
    
    if (locationProvider.locations.isNotEmpty) {
      await weatherProvider.updateAllForecasts(
        locationProvider.locations,
        threshold: settingsProvider.temperatureThreshold,
        notificationsEnabled: settingsProvider.notificationsEnabled,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frost Guard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Consumer3<LocationProvider, WeatherProvider, SettingsProvider>(
          builder: (context, locationProvider, weatherProvider, settingsProvider, _) {
            // Zeige Ladeindikator, wenn Daten geladen werden
            if (locationProvider.isLoading || weatherProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // Zeige Fehlermeldung an, wenn ein Fehler aufgetreten ist
            if (locationProvider.error.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Es ist ein Fehler aufgetreten:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(locationProvider.error),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              );
            }
            
            // Keine Standorte vorhanden - zeige Einrichtungsbildschirm
            if (locationProvider.locations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Standorte eingerichtet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: ThemeConstants.largePadding),
                      child: Text(
                        'Fügen Sie Standorte hinzu, um Wetterdaten und Frostwarnungen zu erhalten.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _showAddLocationDialog,
                      child: const Text('Standort hinzufügen'),
                    ),
                  ],
                ),
              );
            }
            
            // Standorte vorhanden - zeige Wetterkarten
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(ThemeConstants.normalPadding),
              itemCount: locationProvider.locations.length + 1, // +1 für den "Aktualisiert" Text
              onReorder: (oldIndex, newIndex) {
                // Ignoriere den letzten Eintrag (Aktualisiert-Text)
                if (oldIndex >= locationProvider.locations.length || 
                    newIndex >= locationProvider.locations.length) {
                  return;
                }
                locationProvider.reorderLocations(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                // Der letzte Index ist für den "Aktualisiert" Text
                if (index == locationProvider.locations.length) {
                  return Padding(
                    key: const ValueKey('updated-text'),
                    padding: const EdgeInsets.only(top: ThemeConstants.normalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Aktualisiert: ${_getLastUpdatedText(weatherProvider.lastUpdated)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: _refreshData,
                          tooltip: 'Aktualisieren',
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                        ),
                      ],
                    ),
                  );
                }
                
                // Ansonsten zeige die Wetterkarte
                final location = locationProvider.locations[index];
                bool hasFrostWarning = weatherProvider.hasFrostWarning(location.id);
                return WeatherCard(
                  key: ValueKey(location.id),
                  location: location,
                  weatherData: weatherProvider.getWeatherFor(location.id),
                  hasFrostWarning: hasFrostWarning,
                  onDelete: () async {
                    await locationProvider.removeLocation(location.id);
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLocationDialog,
        tooltip: 'Standort hinzufügen',
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }

  String _getLastUpdatedText(DateTime? lastUpdated) {
    if (lastUpdated == null) {
      return 'nie';
    }

    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'vor wenigen Sekunden';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Minuten';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Stunden';
    } else {
      return 'vor ${difference.inDays} Tagen';
    }
  }
}
