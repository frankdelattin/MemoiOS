import 'package:snapp_app/data/models/base_model.dart';
import 'package:snapp_app/data/models/cluster_image_model.dart';
import 'package:snapp_app/repositories/core/base_repository.dart';
import 'package:snapp_app/repositories/core/constants/table_constants.dart';

class ClusterImagesRepository extends BaseRepository<ClusterImageModel> {
  ClusterImagesRepository({required super.database});

  @override
  String get tableName => TableNameConstants.clusterImages;

  @override
  ModelCreator<ClusterImageModel> get creator => ClusterImageModel.fromMap;

  Future<List<ClusterImageModel>> findByClusterId(int clusterId) async {
    return findAllByQuery(condition: "cluster_id = ?", arguments: [clusterId]);
  }
}
