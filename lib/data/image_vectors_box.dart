import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';
import 'package:snapp_app/data/enums/image_vector_status.dart';
import 'package:snapp_app/data/models/base_box.dart';

@Entity()
class ImageVectorsBox extends BaseBox {
  @Id()
  int id = 0;

  @Unique(onConflict: ConflictStrategy.replace)
  String imageId;

  @HnswIndex(
      dimensions: 768,
      distanceType: VectorDistanceType.dotProductNonNormalized,
      indexingSearchCount: 200)
  Float32List vectors;

  @Index()
  int imageModifiedDate;

  @Transient()
  ImageVectorStatus? status;

  @Index()
  int? get dbStatus => status?.value;

  set dbStatus(int? value) => status = ImageVectorStatus.fromValue(value);

  DateTime createdAt;

  ImageVectorsBox({
    required this.imageId,
    required this.vectors,
    this.status,
    required this.createdAt,
    required this.imageModifiedDate,
  });
}
