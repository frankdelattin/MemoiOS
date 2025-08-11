import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/aggregates/cluster_images_aggregate.dart';
import 'package:snapp_app/presentations/widgets/asset_image_marker.dart';
import 'package:snapp_app/services/event_based_cluster_service.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/data/image_metadata.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class WorldMapPage extends StatefulWidget {
  const WorldMapPage({super.key});

  @override
  State<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  late MapTileLayerController _mapController;
  late MapZoomPanBehavior _zoomPanBehavior;
  final EventBasedClusterService _eventBasedClusterService =
      GetIt.I<EventBasedClusterService>();

  late List<ClusterImagesAggregate> clusterAggregates = [];
  late Map<String, ImageMetadata> imageMetadataMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    _mapController = MapTileLayerController();
    _zoomPanBehavior = MapZoomPanBehavior(
      enableDoubleTapZooming: true,
      enablePanning: true,
      zoomLevel: 2,
    );
  }

  Future<void> _load() async {
    await _loadClusters();
    await _loadAssetEntitiesAndImageMetadata();
  }

  Future _loadClusters() async {
    clusterAggregates = await _eventBasedClusterService.getClusters();
  }

  Future _loadAssetEntitiesAndImageMetadata() async {
    for (var cluster in clusterAggregates) {
      final clusterFirstImageId = cluster.images.first.imageId;
      final assetEntity =
          await GetIt.I<ImageService>().getAssetEntity(clusterFirstImageId);
      final imageMetadata =
          await GetIt.I<ImageService>().getMetadata(assetEntity!);
      imageMetadataMap[clusterFirstImageId] = imageMetadata;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }
          return WorldMapWidget(
            mapController: _mapController,
            zoomPanBehavior: _zoomPanBehavior,
            clusterAggregates: clusterAggregates,
            imageMetadataMap: imageMetadataMap,
          );
        },
      ),
    );
  }
}

class WorldMapWidget extends StatelessWidget {
  const WorldMapWidget({
    super.key,
    required MapTileLayerController mapController,
    required MapZoomPanBehavior zoomPanBehavior,
    required this.clusterAggregates,
    required this.imageMetadataMap,
  })  : _mapController = mapController,
        _zoomPanBehavior = zoomPanBehavior;

  final MapTileLayerController _mapController;
  final MapZoomPanBehavior _zoomPanBehavior;
  final List<ClusterImagesAggregate> clusterAggregates;
  final Map<String, ImageMetadata> imageMetadataMap;

  @override
  Widget build(BuildContext context) {
    return SfMaps(
      layers: [
        MapTileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          initialFocalLatLng: MapLatLng(0, 0),
          initialZoomLevel: 2,
          markerTooltipBuilder: (BuildContext context, int index) {
            return Text('${clusterAggregates[index].images.length} images');
          },
          controller: _mapController,
          zoomPanBehavior: _zoomPanBehavior,
          markerBuilder: (BuildContext context, int index) {
            final clusterFirstImageId =
                clusterAggregates[index].images.first.imageId;
            final imageMetadata = imageMetadataMap[clusterFirstImageId]!;

            return MapMarker(
              latitude: imageMetadata.latitude,
              longitude: imageMetadata.longitude,
              child:
                  AssetImageMarker(clusterAggregate: clusterAggregates[index]),
            );
          },
          initialMarkersCount: clusterAggregates.length,
        ),
      ],
    );
  }
}
