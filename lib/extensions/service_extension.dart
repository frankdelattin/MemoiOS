import 'package:device_calendar/device_calendar.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/background/work_manager_service.dart';
import 'package:snapp_app/repositories/cache/cache_repository.dart';
import 'package:snapp_app/repositories/cluster_images_repository.dart';
import 'package:snapp_app/repositories/cluster_repository.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';
import 'package:snapp_app/services/calendar_service.dart';
import 'package:snapp_app/services/clustering_service.dart';
import 'package:snapp_app/services/event_based_cluster_service.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/onnx_runtime_service.dart';
import 'package:snapp_app/services/vector_service.dart';
import 'package:workmanager/workmanager.dart';

extension ServiceExtension on GetIt {
  void registerServices() {
    _registerCalendarService();
    _registerImageService();
    _registerClusteringService();
    _registerEventBasedClusteringService();
    _registerOnnxRuntimeService();
    _registerVectorService();
    _registerOnChargeBackgroundService();
  }

  void registerServicesForBackground() {
    _registerImageService();
    _registerOnnxRuntimeService();
    _registerVectorService();
  }

  void _registerCalendarService() {
    registerSingletonAsync<CalendarService>(
      () async => CalendarService(deviceCalendarPlugin: this()),
      dependsOn: [DeviceCalendarPlugin],
    );
  }

  void _registerImageService() {
    registerSingletonAsync<ImageService>(
      () async => ImageService(),
    );
  }

  void _registerClusteringService() {
    registerSingletonAsync<ClusteringService>(
      () async => ClusteringService(cacheRepository: this()),
      dependsOn: [CacheRepository],
    );
  }

  void _registerEventBasedClusteringService() {
    registerSingletonAsync<EventBasedClusterService>(
      () async => EventBasedClusterService(
        imageService: this(),
        clusteringService: this(),
        calendarService: this(),
        clusterRepository: this(),
        clusterImagesRepository: this(),
      ),
      dependsOn: [
        ImageService,
        ClusteringService,
        CalendarService,
        ClusterRepository,
        ClusterImagesRepository,
      ],
    );
  }

  void _registerVectorService() {
    registerSingletonAsync<VectorService>(
      () async => VectorService(
        imageService: this(),
        cacheRepository: this(),
        imageVectorsRepository: this(),
        onnxRuntimeService: this(),
      ),
      dependsOn: [
        ImageService,
        CacheRepository,
        ImageVectorsRepository,
        OnnxRuntimeService,
      ],
    );
  }

  void _registerOnChargeBackgroundService() {
    registerSingletonAsync<WorkManagerService>(
      () async => WorkManagerService(workmanager: this()),
      dependsOn: [Workmanager],
    );
  }

  void _registerOnnxRuntimeService() {
    registerSingletonAsync<OnnxRuntimeService>(
      () async => OnnxRuntimeService(),
      dependsOn: [],
    );
  }
}
