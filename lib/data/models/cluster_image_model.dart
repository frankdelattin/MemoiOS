import 'package:snapp_app/data/models/base_model.dart';

class ClusterImageModel implements BaseModel {
  final int clusterId;
  final String imageId;

  ClusterImageModel({required this.clusterId, required this.imageId});

  @override
  Map<String, dynamic> toMap() {
    return {
      "cluster_id": clusterId,
      "image_id": imageId,
    };
  }

  @override
  factory ClusterImageModel.fromMap(Map<String, dynamic> map) {
    return ClusterImageModel(
      clusterId: map["cluster_id"],
      imageId: map["image_id"],
    );
  }
}
