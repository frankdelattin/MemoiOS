import 'package:snapp_app/data/models/cluster_image_model.dart';
import 'package:snapp_app/data/models/cluster_model.dart';

class ClusterImagesAggregate {
  final ClusterModel cluster;
  final List<ClusterImageModel> images;

  ClusterImagesAggregate({required this.cluster, required this.images});
}
