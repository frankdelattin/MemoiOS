import 'dart:math';

import 'package:simple_cluster/src/dbscan.dart';
import 'package:snapp_app/constants/cache_keys.dart';
import 'package:snapp_app/data/image_metadata.dart';
import 'package:snapp_app/repositories/cache/cache_repository.dart';

class ClusteringService {
  static const double R = 6371.0;

  final CacheRepository _cacheRepository;

  ClusteringService({required CacheRepository cacheRepository})
      : _cacheRepository = cacheRepository;

  double _haversineDistance(List<double> a, List<double> b) {
    double lat1 = a[0];
    double lon1 = a[1];
    double lat2 = b[0];
    double lon2 = b[1];

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double phi1 = _degreesToRadians(lat1);
    double phi2 = _degreesToRadians(lat2);

    double h = sin(dLat / 2) * sin(dLat / 2) +
        cos(phi1) * cos(phi2) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(h), sqrt(1 - h));

    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<DBSCAN> _getGeoDbscan() async {
    int epsilon =
        await _cacheRepository.getInt(CacheKeys.geoEpsilon, defaultValue: 100);
    int minPoints =
        await _cacheRepository.getInt(CacheKeys.minPoints, defaultValue: 10);

    return DBSCAN(
      epsilon: epsilon.toDouble(),
      minPoints: minPoints,
      distanceMeasure: _haversineDistance,
    );
  }

  Future<DBSCAN> _getDatetimeDbscan() async {
    int epsilon = await _cacheRepository.getInt(CacheKeys.datetimeEpsilon,
        defaultValue: 604800000); // 7 days
    int minPoints =
        await _cacheRepository.getInt(CacheKeys.minPoints, defaultValue: 10);

    return DBSCAN(
      epsilon: epsilon.toDouble(),
      minPoints: minPoints,
      distanceMeasure: (a, b) => (a[0] - b[0]).abs(),
    );
  }

  Future<List<List<ImageMetadata>>> clusterImages(
      List<ImageMetadata> images) async {
    images = images
        .where((element) => element.latitude != 0 && element.longitude != 0)
        .toList();

    List<List<double>> geoData = images
        .map((element) => [
              element.latitude,
              element.longitude,
            ])
        .toList();

    var geoDbscan = await _getGeoDbscan();
    var geoClusters = geoDbscan.run(geoData);
    List<List<int>> clusters = [];
    for (var geoCluster in geoClusters) {
      var datetimeData = geoCluster
          .map((element) => [
                images[element].dateTime.millisecondsSinceEpoch.toDouble(),
              ])
          .toList();

      var datetimeDbscan = await _getDatetimeDbscan();
      var datetimeClusters = datetimeDbscan.run(datetimeData);

      for (var timeCluster in datetimeClusters) {
        var clusterIndices =
            timeCluster.map((timeIndex) => geoCluster[timeIndex]).toList();
        clusters.add(clusterIndices);
      }
    }

    var result = <List<ImageMetadata>>[];
    for (var cluster in clusters) {
      result.add(cluster.map((element) => images[element]).toList());
    }

    return result;
  }
}
