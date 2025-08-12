import 'dart:ui';

import 'package:get_it/get_it.dart';
import 'package:snapp_app/background/work_manager_service.dart';
import 'package:snapp_app/constants/cache_keys.dart';
import 'package:snapp_app/data/enums/image_vector_status.dart';
import 'package:snapp_app/repositories/cache/cache_repository.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/vector_service.dart';
import 'package:workmanager/workmanager.dart';

debug() async {
  await GetIt.I<Workmanager>().registerOneOffTask(
    WorkManagerService.aiVectorTask,
    WorkManagerService.aiVectorTask,
    backoffPolicy: BackoffPolicy.linear,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

periodicBackground() async {
  await GetIt.I<Workmanager>().registerProcessingTask(
    WorkManagerService.aiVectorTask,
    WorkManagerService.aiVectorTask,
  );
}

runFlutterOnnx() async {
  for (int i = 0; i < 100; i++) {
    await GetIt.I<VectorService>().procesNextImages();
    var sendPort =
        IsolateNameServer.lookupPortByName(WorkManagerService.aiVectorPortName);
    sendPort?.send("RUNNING");
  }
}

runNativeOnnx() async {
  await GetIt.I<CacheRepository>().putInt(CacheKeys.lastImageModifiedDate, 0);
  await GetIt.I<ImageVectorsRepository>().deleteAll();
}

vectorDiff() async {
//var image = await GetIt.I<ImageService>().getAssetEntity("726");
  //var generated = await GetIt.I<VectorService>().generateOneImageVector(image!);
  //print("Generated: ${generated.vectors}");
  //var normalized =
  //    await GetIt.I<VectorService>().normalizeVector(generated.vectors);
  //print("Normalized: $normalized");

  //GetIt.I<ImageVectorsRepository>().insert(generated);
  var result = await GetIt.I<ImageVectorsRepository>().getAll();

  for (var e in result) {
    var normalized = await GetIt.I<VectorService>().normalizeVector(e.vectors);
    print("Encoded: ${e.imageId} ${normalized.reversed.toList()}");
  }
  print("hello");
}

void errorPhotos() async {
  var repo = GetIt.I<ImageVectorsRepository>();
  var all = await repo.getAll();
  for (int i = 0; i < 10; i++) {
    all.last.dbStatus = ImageVectorStatus.error.value;
    await repo.update(all.last);
    all.removeLast();
  }
}

void deleteExtraImages() async {
  var imageVectorRepository = GetIt.I<ImageVectorsRepository>();
  var limit = 1000;
  var offset = 0;

  while (true) {
    var all = (await imageVectorRepository.query(limit: limit, offset: offset))
        .toSet();

    if (all.isEmpty) {
      break;
    }

    var imageIds = all.map((e) => e.imageId).toSet();
    var images = await GetIt.I<ImageService>()
        .getImagesByIds(imageIds: imageIds, limit: limit);

    imageIds.removeAll(images.map((e) => e.id));
    if (imageIds.isNotEmpty) {
      await imageVectorRepository.deleteAllByImageIds(imageIds);
    }
    offset += limit;
  }
  print("done");
}

/* import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:snapp_app/data/image_vectors_box.dart';
import 'package:snapp_app/repositories/core/objectbox.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';


debug()
copySqliteToObjectBox() async {
  var objectBox = GetIt.I<ObjectBox>();
  var box = objectBox.store.box<ImageVectorsBox>();
  var offset = 0;
  var limit = 1274;

  for (var i = 0; i < 50; i++) {
    /* var imageVectors = await GetIt.I<ImageVectorsRepository>()
        .findAllByQuery(offset: offset, limit: limit); */
    if (imageVectors.isEmpty) {
      break;
    }
    var imageVectorsBoxes = <ImageVectorsBox>[];
    for (var imageVector in imageVectors) {
      imageVectorsBoxes.add(ImageVectorsBox(
        imageVector.imageId,
        imageVector.vectors as List<double>,
        imageVector.createdAt,
      ));
    }
    await box.putManyAsync(imageVectorsBoxes);
    print("offset: $offset");
  }
  print("done");
  var all = await box.count();
  print(all);
}

calculateDistances() async {
  var objectBox = GetIt.I<ObjectBox>();
  var box = objectBox.store.box<ImageVectorsBox>();
  await box.removeAllAsync();
  copySqliteToObjectBox();
}

List<double> normalizeVector(List<double> vector) {
  double norm = vectorNorm(vector);
  return vector.map((e) => e / norm).toList();
}

double vectorNorm(List<double> vector, {int p = 2}) {
  double sum = 0.0;
  for (var value in vector) {
    sum += pow(value.abs(), p);
  }
  return pow(sum, 1 / p).toDouble();
}
 */
