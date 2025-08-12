import 'dart:math';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:snapp_app/constants/cache_keys.dart';
import 'package:snapp_app/data/enums/image_vector_status.dart';
import 'package:snapp_app/data/image_vectors_box.dart';
import 'package:snapp_app/data/nlp_image.dart';
import 'package:snapp_app/repositories/cache/cache_repository.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/onnx_runtime_service.dart';

class VectorService {
  static const String modelPath = "assets/models/nlp_visualize.onnx";

  final ImageVectorsRepository _imageVectorsRepository;
  final ImageService _imageService;
  final CacheRepository _cacheRepository;
  final OnnxRuntimeService _onnxRuntimeService;

  VectorService(
      {required ImageVectorsRepository imageVectorsRepository,
      required ImageService imageService,
      required CacheRepository cacheRepository,
      required OnnxRuntimeService onnxRuntimeService})
      : _imageVectorsRepository = imageVectorsRepository,
        _imageService = imageService,
        _cacheRepository = cacheRepository,
        _onnxRuntimeService = onnxRuntimeService;

  Future<int> retrieveSyncedCount() {
    return _imageVectorsRepository.count();
  }

  int retrieveFailedCount() {
    return _imageVectorsRepository.getFailedImageCount();
  }

  // Returns a tuple of (hasNext, skipNext)
  Future<(bool, bool)> reprocessFailedImages(int offset) async {
    var failedImageVectorBox =
        await _imageVectorsRepository.getOneFailedImage(offset);
    if (failedImageVectorBox == null) {
      return (false, false);
    }
    var imageAsset =
        await _imageService.getAssetEntity(failedImageVectorBox.imageId);

    if (imageAsset == null) {
      return (true, true);
    }
    var imageVectorsBox = await generateOneImageVector(imageAsset);
    if (imageVectorsBox.status == ImageVectorStatus.success) {
      await _imageVectorsRepository.insert(imageVectorsBox);
      return (true, false);
    }

    return (true, true);
  }

  Future<ImageVectorsBox> generateOneImageVector(AssetEntity imageAsset) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final imageBytes = await _imageService.getImage(imageAsset);
      print("Getting image bytes elapsed ${stopwatch.elapsedMilliseconds}ms");
      stopwatch.reset();

      final vectors = await _onnxRuntimeService.encodeImage(imageBytes);
      print("Imgae encoding elapsed ${stopwatch.elapsedMilliseconds}ms");
      stopwatch.reset();

      return ImageVectorsBox(
        imageId: imageAsset.id,
        vectors: Float32List.fromList(vectors),
        status: ImageVectorStatus.success,
        createdAt: DateTime.now(),
        imageModifiedDate: imageAsset.modifiedDateSecond ?? 0,
      );
    } catch (e) {
      print("Error while processing image: $e");
      return ImageVectorsBox(
        imageId: imageAsset.id,
        vectors: Float32List(0),
        status: ImageVectorStatus.error,
        createdAt: DateTime.now(),
        imageModifiedDate: imageAsset.modifiedDateSecond ?? 0,
      );
    } finally {
      stopwatch.stop();
    }
  }

  Future<bool> procesNextImages() async {
    var lastModifiedDate = await _cacheRepository
        .getInt(CacheKeys.lastImageModifiedDate, defaultValue: -1);

    if (lastModifiedDate == -1) {
      lastModifiedDate =
          await _imageVectorsRepository.getLastImageModifiedDate() ?? -1;
    }

    var imageIds = await _imageVectorsRepository
        .getImageIdsByModifiedDate(lastModifiedDate);

    var imageAsset = (await _imageService.getImages(
            lastModifiedDate: lastModifiedDate,
            excludedImageIds: imageIds,
            limit: 1))
        .firstOrNull;

    if (imageAsset == null) {
      return false;
    }

    var imageVectorsBox = await generateOneImageVector(imageAsset);
    await _imageVectorsRepository.insert(imageVectorsBox);

    await _cacheRepository.putInt(
        CacheKeys.lastImageModifiedDate, imageAsset.modifiedDateSecond ?? 0);
    return true;
  }

  Future<List<ImagePrediction>> getSimilarPhotos(String query) async {
    var stopwatch = Stopwatch()..start();
    var textVector = await _onnxRuntimeService.encodeText(query);
    print("Text encoding elapsed ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.reset();
    print("Text vector: $textVector");
    var txtNorm = normalizeVector(textVector);
    print("Normalizing vector elapsed ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.reset();
    var result =
        await _imageVectorsRepository.getNearestVectors(textVector, 100);
    print("Querying elapsed ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.reset();
    stopwatch.stop();
    var predictions = <ImagePrediction>[];
    for (var e in result) {
      var nrmList = normalizeVector(e.object.vectors);
      var score = calculateSimilarity(nrmList, txtNorm);
      predictions.add(
          ImagePrediction(imageId: e.object.imageId, similarityScore: score));
    }
    predictions.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return predictions;
  }

  double cosineDistance(List<double> vector1, List<double> vector2) {
    double upper = 0;
    double bottomA = 0;
    double bottomB = 0;
    int len = min(vector1.length, vector2.length);
    for (int i = 0; i < len; i++) {
      upper += vector1[i] * vector2[i];
      bottomA += vector1[i] * vector1[i];
      bottomB += vector2[i] * vector2[i];
    }
    double diviser = sqrt(bottomA) * sqrt(bottomB);
    return 1.0 - (diviser != 0 ? (upper / diviser) : 0);
  }

  double calculateSimilarity(
      List<double> imageEmbedding, List<double> textEmbedding) {
    // Perform matrix multiplication
    double result = 0.0;
    for (int i = 0; i < imageEmbedding.length; i++) {
      result += imageEmbedding[i] * textEmbedding[i];
    }

    return result;
  }

  double vectorNorm(List<double> vector, {int p = 2}) {
    double sum = 0.0;
    for (var value in vector) {
      sum += pow(value.abs(), p);
    }
    return pow(sum, 1 / p).toDouble();
  }

  List<double> normalizeVector(List<double> vector) {
    double norm = vectorNorm(vector);
    var dbl = vector.map((e) => e / norm).toList();
    return dbl;
  }

  Future syncVectors() async {
    var lastModifiedDate =
        await _imageVectorsRepository.getLastImageModifiedDate();
    var actualCount = await _imageService.getAllImagesCount(
        maxModifiedDate: lastModifiedDate);
    var dbCount = await _imageVectorsRepository.count();
    print("actualCount: $actualCount");
    print("dbCount: $dbCount");
    print("lastModifiedDate: $lastModifiedDate");
    if (actualCount < dbCount) {
      await _deleteExtraImages();
    } else if (actualCount > dbCount) {
      print("FATAL ERROR: Actual count is greater than db count");
    }
  }

  Future _deleteExtraImages() async {
    var limit = 1000;
    var offset = 0;

    while (true) {
      var all =
          (await _imageVectorsRepository.query(limit: limit, offset: offset))
              .toSet();

      if (all.isEmpty) {
        break;
      }

      var imageIds = all.map((e) => e.imageId).toSet();
      var images =
          await _imageService.getImagesByIds(imageIds: imageIds, limit: limit);

      imageIds.removeAll(images.map((e) => e.id));
      if (imageIds.isNotEmpty) {
        await _imageVectorsRepository.deleteAllByImageIds(imageIds);
        print("deleted ${imageIds.length} images");
      }
      offset += limit;
    }
  }
}
