import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/constants/cache_keys.dart';
import 'package:snapp_app/repositories/cache/cache_repository.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _geoEpsilonController = TextEditingController();
  final TextEditingController _datetimeEpsilonController =
      TextEditingController();
  final TextEditingController _minPointsController = TextEditingController();

  static const int defaultGeoEpsilon = 100;
  static const int defaultDatetimeEpsilon = 604800000;
  static const int defaultMinPoints = 10;

  @override
  void initState() {
    super.initState();
    _loadClusterSettings();
  }

  Future<void> _loadClusterSettings() async {
    _geoEpsilonController.text = (await GetIt.I<CacheRepository>()
            .getInt(CacheKeys.geoEpsilon, defaultValue: defaultGeoEpsilon))
        .toString();
    _datetimeEpsilonController.text = ((await GetIt.I<CacheRepository>().getInt(
                CacheKeys.datetimeEpsilon,
                defaultValue: defaultDatetimeEpsilon)) /
            (1000 * 60 * 60))
        .toInt()
        .toString();
    _minPointsController.text = (await GetIt.I<CacheRepository>()
            .getInt(CacheKeys.minPoints, defaultValue: defaultMinPoints))
        .toString();
  }

  Future<void> _saveClusterSettings() async {
    await GetIt.I<CacheRepository>().putInt(CacheKeys.geoEpsilon,
        int.parse(_geoEpsilonController.text.replaceAll(',', '.')));
    await GetIt.I<CacheRepository>().putInt(
        CacheKeys.datetimeEpsilon,
        (double.parse(_datetimeEpsilonController.text) * 1000 * 60 * 60)
            .toInt());
    await GetIt.I<CacheRepository>().putInt(CacheKeys.minPoints,
        int.parse(_minPointsController.text.replaceAll(',', '.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Clustering Settings',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _geoEpsilonController,
              decoration: InputDecoration(labelText: 'Maximum Distance (km)'),
              keyboardType: TextInputType.numberWithOptions(decimal: false),
            ),
            TextField(
              controller: _datetimeEpsilonController,
              decoration: InputDecoration(labelText: 'Maximum Time (hours)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _minPointsController,
              decoration:
                  InputDecoration(labelText: 'Minimum Images in a Cluster'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveClusterSettings();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
