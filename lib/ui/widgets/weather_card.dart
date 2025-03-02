import 'package:flutter/material.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:frost_guard/core/utils/date_utils.dart';
import 'package:frost_guard/core/utils/temperature_utils.dart';
import 'package:frost_guard/core/services/weather_service.dart';
import 'package:frost_guard/core/constants/theme_constants.dart';
import 'package:provider/provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';

class WeatherCard extends StatefulWidget {
  final Location location;
  final WeatherData? weatherData;
  final bool hasFrostWarning;
  final VoidCallback onDelete;

  const WeatherCard({
    Key? key,
    required this.location,
    required this.weatherData,
    this.hasFrostWarning = false,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final temperatureUnit = settingsProvider.temperatureUnit;
    
    return Dismissible(
      key: Key(widget.location.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        widget.onDelete();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: ThemeConstants.normalPadding),
        color: widget.hasFrostWarning 
            ? (theme.brightness == Brightness.dark 
                ? ThemeConstants.frostWarningDarkColor 
                : ThemeConstants.frostWarningLightColor)
            : null,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(ThemeConstants.normalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme, temperatureUnit),
                if (_isExpanded) ...[
                  if (widget.hasFrostWarning)
                    _buildFrostWarningMessage(context, theme, settingsProvider),
                  if (widget.weatherData == null || widget.weatherData!.daily.isEmpty)
                    _buildLoadingState(theme)
                  else
                    _buildWeatherContent(context, theme, temperatureUnit),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, String temperatureUnit) {
    // Tiefsttemperatur für den kompakten Zustand
    double? minTemp;
    if (widget.weatherData != null && widget.weatherData!.daily.isNotEmpty) {
      final today = widget.weatherData!.daily[0];
      minTemp = TemperatureUtils.getTemperatureInUnit(
        today.temp.min, 
        temperatureUnit
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                widget.location.isCurrentLocation 
                    ? Icons.my_location 
                    : Icons.location_on,
                color: widget.hasFrostWarning 
                    ? ThemeConstants.frostWarningColor
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.location.name,
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: widget.hasFrostWarning 
                        ? ThemeConstants.frostWarningColor
                        : null,
                    fontWeight: widget.hasFrostWarning ? FontWeight.bold : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!_isExpanded && minTemp != null)
          Text(
            TemperatureUtils.formatTemperature(minTemp, temperatureUnit),
            style: theme.textTheme.titleMedium!.copyWith(
              color: _isTempBelowThreshold(minTemp, context) 
                  ? ThemeConstants.frostWarningColor 
                  : null,
              fontWeight: _isTempBelowThreshold(minTemp, context) 
                  ? FontWeight.bold 
                  : null,
            ),
          ),
        if (_isExpanded)
          Icon(
            Icons.keyboard_arrow_up,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          )
        else
          Icon(
            Icons.keyboard_arrow_down,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
      ],
    );
  }

  bool _isTempBelowThreshold(double temperature, BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final threshold = settingsProvider.temperatureThreshold;
    
    if (settingsProvider.temperatureUnit == 'fahrenheit') {
      return temperature < TemperatureUtils.celsiusToFahrenheit(threshold);
    }
    
    return temperature < threshold;
  }

  Widget _buildFrostWarningMessage(BuildContext context, ThemeData theme, SettingsProvider settingsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        Text(
          'Es wird heute Nacht in ${widget.location.name} Frost geben. Die Temperatur wird voraussichtlich unter den eingestellten Schwellenwert von ${TemperatureUtils.formatTemperature(settingsProvider.temperatureThreshold, settingsProvider.temperatureUnit)} fallen.',
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
        const Divider(color: Colors.white30),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: ThemeConstants.normalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 12),
          Text(
            'Wetterdaten werden geladen...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context, ThemeData theme, String temperatureUnit) {
    if (widget.weatherData!.daily.isEmpty) {
      return const SizedBox.shrink();
    }

    final weatherService = WeatherService();
    final today = widget.weatherData!.daily[0];
    final currentCondition = today.weather.isNotEmpty ? today.weather[0] : null;
    
    // Temperaturen in der korrekten Einheit
    final double minTemp = TemperatureUtils.getTemperatureInUnit(
      today.temp.min, 
      temperatureUnit
    );
    final double maxTemp = TemperatureUtils.getTemperatureInUnit(
      today.temp.max, 
      temperatureUnit
    );
    final double nightTemp = TemperatureUtils.getTemperatureInUnit(
      today.temp.night, 
      temperatureUnit
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        
        // Aktuelles Wetter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heute',
                  style: theme.textTheme.titleLarge,
                ),
                if (currentCondition != null)
                  Text(
                    currentCondition.description,
                    style: theme.textTheme.bodyMedium,
                  ),
              ],
            ),
            if (currentCondition != null)
              Image.network(
                weatherService.getWeatherIconUrl(currentCondition.icon),
                width: 60,
                height: 60,
                errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 60),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Temperaturbereich für heute
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTemperatureItem(
              context,
              theme, 
              'Tagsüber', 
              TemperatureUtils.formatTemperature(maxTemp, temperatureUnit),
              Icons.wb_sunny_outlined,
            ),
            _buildTemperatureItem(
              context,
              theme, 
              'Nachts', 
              TemperatureUtils.formatTemperature(nightTemp, temperatureUnit),
              Icons.nightlight_round,
              isNightTemp: true,
            ),
            _buildTemperatureItem(
              context,
              theme, 
              'Min', 
              TemperatureUtils.formatTemperature(minTemp, temperatureUnit),
              Icons.arrow_downward,
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 3-Tage-Vorhersage
        _buildForecastSection(context, theme, temperatureUnit),
      ],
    );
  }

  Widget _buildTemperatureItem(
    BuildContext context,
    ThemeData theme, 
    String label, 
    String temperature, 
    IconData icon,
    {bool isNightTemp = false}
  ) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Hervorhebung der Nachttemperatur, wenn sie unter dem Schwellenwert liegt
    final isBelowThreshold = isNightTemp && 
                           double.tryParse(temperature.replaceAll(RegExp(r'[^\d.-]'), '')) != null &&
                           double.parse(temperature.replaceAll(RegExp(r'[^\d.-]'), '')) < 
                           settingsProvider.temperatureThreshold;
    
    final Color textColor = isBelowThreshold 
        ? ThemeConstants.frostWarningColor
        : theme.textTheme.bodyLarge!.color!;
        
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            temperature,
            style: theme.textTheme.titleMedium!.copyWith(
              color: textColor,
              fontWeight: isBelowThreshold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(BuildContext context, ThemeData theme, String temperatureUnit) {
    // Begrenze auf 3 Tage und überspringe den heutigen Tag
    final forecasts = widget.weatherData!.daily.length > 3 
        ? widget.weatherData!.daily.sublist(1, 4) 
        : widget.weatherData!.daily.sublist(1);
        
    final weatherService = WeatherService();
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          'Vorhersage',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: forecasts.map((day) {
            final date = DateTimeUtils.fromUnixTimestamp(day.dt);
            final weatherIcon = day.weather.isNotEmpty ? day.weather[0].icon : '';
            
            // Temperaturen in der korrekten Einheit
            final double dayTemp = TemperatureUtils.getTemperatureInUnit(
              day.temp.day, 
              temperatureUnit
            );
            final double nightTemp = TemperatureUtils.getTemperatureInUnit(
              day.temp.night, 
              temperatureUnit
            );
            
            return Expanded(
              child: Column(
                children: [
                  Text(
                    DateTimeUtils.formatWeekday(date),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  if (weatherIcon.isNotEmpty)
                    Image.network(
                      weatherService.getWeatherIconUrl(weatherIcon),
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 40),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    TemperatureUtils.formatTemperature(dayTemp, temperatureUnit),
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    TemperatureUtils.formatTemperature(nightTemp, temperatureUnit),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
