import 'package:snapp_app/data/enums/image_vector_status.dart';
import 'package:snapp_app/data/image_vectors_box.dart';
import 'package:snapp_app/objectbox.g.dart';
import 'package:snapp_app/repositories/core/base_objectbox_repository.dart';

class ImageVectorsRepository extends BaseObjectBoxRepository<ImageVectorsBox> {
  ImageVectorsRepository({required super.objectStore});

  Future<ImageVectorsBox> findByImageId(String imageId) async {
    var result = await query(
        condition: ImageVectorsBox_.imageId.equals(imageId), limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    throw Exception('Entity not found');
  }

  int getFailedImageCount() {
    return countByQuery(
        ImageVectorsBox_.dbStatus.equals(ImageVectorStatus.error.value));
  }

  Future<ImageVectorsBox?> getOneFailedImage(int offset) async {
    var result = await query(
        condition:
            ImageVectorsBox_.dbStatus.equals(ImageVectorStatus.error.value),
        offset: offset,
        limit: 1);
    return result.firstOrNull;
  }

  Future<List<String>> getImageIdsByModifiedDate(int modifiedDate) async {
    var result = await query(
      condition: ImageVectorsBox_.imageModifiedDate.equals(modifiedDate),
    );

    if (result.isEmpty) {
      return [];
    }
    return result.map((e) => e.imageId).toList();
  }

  Future<int?> getLastImageModifiedDate() async {
    var result = await query(
      orderBy: ImageVectorsBox_.imageModifiedDate,
      order: Order.descending,
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }
    return result.first.imageModifiedDate;
  }

  Future<List<ObjectWithScore<ImageVectorsBox>>> getNearestVectors(
      List<double> vector, int limit) async {
    return await queryWithScores(
        condition: ImageVectorsBox_.vectors.nearestNeighborsF32(vector, 100000),
        limit: limit);
  }

  deleteAllByImageIds(Set<String> imageIds) async {
    deleteByQuery(condition: ImageVectorsBox_.imageId.oneOf(imageIds.toList()));
  }
}
