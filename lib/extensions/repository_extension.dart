import 'package:get_it/get_it.dart';
import 'package:snapp_app/objectbox.g.dart';
import 'package:snapp_app/repositories/cluster_images_repository.dart';
import 'package:snapp_app/repositories/cluster_repository.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';
import 'package:sqflite/sqflite.dart';

extension RepositoryExtension on GetIt {
  void registerRepositories() {
    _registerClusterRepository();
    _registerCusterImageRepository();
    _registerImageVectorsRepository();
  }

  void registerRepositoriesForBackground() {
    _registerImageVectorsRepository();
  }

  void _registerImageVectorsRepository() {
    registerSingletonAsync<ImageVectorsRepository>(
      () async => ImageVectorsRepository(objectStore: this()),
      dependsOn: [Store],
    );
  }

  void _registerClusterRepository() {
    registerSingletonAsync<ClusterRepository>(
      () async => ClusterRepository(database: this()),
      dependsOn: [Database],
    );
  }

  void _registerCusterImageRepository() {
    registerSingletonAsync<ClusterImagesRepository>(
      () async => ClusterImagesRepository(database: this()),
      dependsOn: [Database],
    );
  }
}
