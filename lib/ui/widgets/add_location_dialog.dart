import 'package:flutter/material.dart';
import 'package:frost_guard/core/constants/theme_constants.dart';
import 'package:frost_guard/core/errors/exceptions.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';
import 'package:frost_guard/providers/weather_provider.dart';
import 'package:provider/provider.dart';

class AddLocationDialog extends StatefulWidget {
  const AddLocationDialog({Key? key}) : super(key: key);

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Location> _searchResults = [];
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    setState(() {
      _isSearching = true;
      _searchQuery = _searchController.text.trim();
      _errorMessage = '';
    });

    if (_searchQuery.isNotEmpty) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final results = await locationProvider.searchLocations(_searchQuery);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _addLocation(Location location) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    
    // Standort hinzufügen
    await locationProvider.addLocation(location);
    
    // Wetterdaten für den neuen Standort abrufen
    await weatherProvider.updateForecast(
      location, 
      settingsProvider.temperatureThreshold,
      settingsProvider.notificationsEnabled
    );
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _addCurrentLocation() async {
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      
      // Aktuellen Standort hinzufügen
      final location = await locationProvider.addCurrentLocation();
      
      // Wetterdaten für den neuen Standort abrufen, wenn der Standort erfolgreich hinzugefügt wurde
      if (location != null) {
        await weatherProvider.updateForecast(
          location, 
          settingsProvider.temperatureThreshold,
          settingsProvider.notificationsEnabled
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (e is LocationException) {
        setState(() {
          _errorMessage = e.message;
          _isSearching = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Fehler beim Hinzufügen des aktuellen Standorts: $e';
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Standort hinzufügen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Stadt, PLZ oder Adresse eingeben',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ThemeConstants.inputBorderRadius,
                  ),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                // Wenn ein Fehler aufgetreten ist
                if (locationProvider.error.isNotEmpty && _errorMessage.isEmpty) {
                  return Text(
                    locationProvider.error,
                    style: TextStyle(color: theme.colorScheme.error),
                  );
                }
                
                // Wenn eine Suche durchgeführt wird
                if (_isSearching || locationProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                // Wenn Suchergebnisse vorhanden sind
                if (_searchResults.isNotEmpty) {
                  return Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        return ListTile(
                          title: Text(location.name),
                          onTap: () => _addLocation(location),
                        );
                      },
                    ),
                  );
                }
                
                // Wenn eine Suche durchgeführt wurde, aber keine Ergebnisse gefunden wurden
                if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
                  return const Text(
                    'Keine Standorte gefunden. Bitte versuchen Sie eine andere Suchanfrage.',
                  );
                }
                
                // Initial, bevor eine Suche durchgeführt wurde
                return const Text(
                  'Suchen Sie nach einem Standort, um ihn zu Ihrer Liste hinzuzufügen.',
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Abbrechen'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Aktuellen Standort hinzufügen'),
          onPressed: _isSearching ? null : _addCurrentLocation,
        ),
      ],
    );
  }
}
