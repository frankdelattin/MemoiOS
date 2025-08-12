import 'package:snapp_app/data/models/base_model.dart';

class ImageVectorModel implements BaseModel {
  final String imageId;
  final List<Object?> vectors;
  final DateTime createdAt;

  ImageVectorModel({
    required this.imageId,
    required this.vectors,
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      "image_id": imageId,
      "vectors": vectors.map((e) => e.toString()).join(","),
      "created_at": createdAt.toUtc().toIso8601String(),
    };
  }

  factory ImageVectorModel.fromMap(Map<String, dynamic> map) {
    return ImageVectorModel(
      imageId: map["image_id"],
      vectors: map["vectors"]
          .toString()
          .substring(1, map["vectors"].toString().length - 1)
          .split(",")
          .map((e) => double.parse(e))
          .toList(),
      createdAt: DateTime.parse(map["created_at"]).toLocal(),
    );
  }
}
