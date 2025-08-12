import 'package:snapp_app/aggregates/cluster_images_aggregate.dart';
import 'package:snapp_app/data/models/cluster_image_model.dart';
import 'package:snapp_app/data/models/cluster_model.dart';
import 'package:snapp_app/data/image_metadata.dart';
import 'package:snapp_app/repositories/cluster_images_repository.dart';
import 'package:snapp_app/repositories/cluster_repository.dart';
import 'package:snapp_app/services/clustering_service.dart';
import 'package:snapp_app/services/calendar_service.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:uuid/uuid.dart';

class EventBasedClusterService {
  final ImageService _imageService;
  final ClusterRepository _clusterRepository;
  final ClusterImagesRepository _clusterImagesRepository;
  final CalendarService _calendarService;
  final ClusteringService _clusteringService;

  EventBasedClusterService(
      {required ImageService imageService,
      required ClusterRepository clusterRepository,
      required ClusterImagesRepository clusterImagesRepository,
      required CalendarService calendarService,
      required ClusteringService clusteringService})
      : _imageService = imageService,
        _clusterRepository = clusterRepository,
        _clusterImagesRepository = clusterImagesRepository,
        _calendarService = calendarService,
        _clusteringService = clusteringService;

  Future<void> processAllClusters() async {
    var images = await _imageService.getAllImageAssetEntities();
    var imageMetadataFutures =
        images.map((element) => _imageService.getMetadata(element)).toList();

    var imageMetadata = await Future.wait(imageMetadataFutures);
    var clusters = await _clusteringService.clusterImages(imageMetadata);

    await clearClusters();
    for (var cluster in clusters) {
      var startTime = _getStartTime(cluster);
      var endTime = _getEndTime(cluster);
      var events =
          await _calendarService.getCalendarEventsInRange(startTime, endTime);

      var clusterEntity = ClusterModel(
        name: events.isNotEmpty
            ? events.first.title ?? "NO TITLE"
            : Uuid().v4().toString(),
        createdAt: DateTime.now(),
      );
      await _saveCluster(clusterEntity, cluster);
    }
  }

  Future<List<ClusterImagesAggregate>> getClusters() async {
    List<ClusterImagesAggregate> clusterAggregates = [];
    var clusters = await _clusterRepository.findAll();
    for (var cluster in clusters) {
      var clusterImages =
          await _clusterImagesRepository.findByClusterId(cluster.id!);
      clusterAggregates
          .add(ClusterImagesAggregate(cluster: cluster, images: clusterImages));
    }
    return clusterAggregates;
  }

  Future<void> clearClusters() async {
    await _clusterRepository.deleteAll();
    await _clusterImagesRepository.deleteAll();
  }

  Future<void> _saveCluster(
      ClusterModel cluster, List<ImageMetadata> clusterImages) async {
    var clusterId = await _clusterRepository.insert(cluster);
    await _clusterImagesRepository.insertAll(clusterImages
        .map((e) => ClusterImageModel(clusterId: clusterId, imageId: e.id))
        .toList());
  }

  _getStartTime(List<ImageMetadata> clusterImages) {
    //earliest image datetime
    var earliestImage =
        clusterImages.reduce((a, b) => a.dateTime.isBefore(b.dateTime) ? a : b);
    return earliestImage.dateTime;
  }

  _getEndTime(List<ImageMetadata> clusterImages) {
    //latest image datetime
    var latestImage =
        clusterImages.reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b);
    return latestImage.dateTime;
  }
}
