import 'package:snapp_app/data/models/base_model.dart';
import 'package:snapp_app/data/models/cluster_model.dart';
import 'package:snapp_app/repositories/core/base_repository.dart';
import 'package:snapp_app/repositories/core/constants/table_constants.dart';

class ClusterRepository extends BaseRepository<ClusterModel> {
  ClusterRepository({required super.database});

  @override
  String get tableName => TableNameConstants.cluster;

  @override
  ModelCreator<ClusterModel> get creator => ClusterModel.fromMap;
}
