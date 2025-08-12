import 'dart:isolate';
import 'dart:ui';

import 'package:get_it/get_it.dart';
import 'package:snapp_app/background_startup.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/vector_service.dart';
import 'package:workmanager/workmanager.dart';

class WorkManagerService {
  static const String aiProcessPeriodicTask = "ai-process-periodic-task";
  static const String aiVectorTask = "ai-vector-task";
  static const String syncDeletedVectorsTask = "sync-deleted-vectors-task";
  static const String aiVectorPortName = "ai-vector-port";

  final Workmanager _workmanager;
  bool _isInitialized = false;

  WorkManagerService({
    required Workmanager workmanager,
  }) : _workmanager = workmanager;

  ReceivePort? aiVectorPort;

  void observeService(void Function(dynamic status) fn) {
    registerPort();
    print("observeService called");
    aiVectorPort!.listen((data) {
      fn(data);
    });
  }

  void registerPort() {
    aiVectorPort?.close();
    aiVectorPort = ReceivePort();
    IsolateNameServer.removePortNameMapping(
        WorkManagerService.aiVectorPortName);
    IsolateNameServer.registerPortWithName(
        aiVectorPort!.sendPort, WorkManagerService.aiVectorPortName);
  }

  Future initialize() async {
    if (_isInitialized) {
      return;
    }
    await _workmanager.initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    _isInitialized = true;
    await _workmanager.registerPeriodicTask(
      WorkManagerService.aiProcessPeriodicTask,
      WorkManagerService.aiProcessPeriodicTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
    await _workmanager.registerPeriodicTask(
      WorkManagerService.syncDeletedVectorsTask,
      WorkManagerService.syncDeletedVectorsTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() async {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case WorkManagerService.aiProcessPeriodicTask:
        await handleAiProcessPeriodicTask();
        break;
      case WorkManagerService.aiVectorTask:
        await handleAiVectorTask();
        break;
      case WorkManagerService.syncDeletedVectorsTask:
        await handleSyncDeletedVectorsTask();
        break;
      default:
        return Future.value(true);
    }
    return Future.value(true);
  });
}

handleSyncDeletedVectorsTask() async {
  await BackgroundStartup.configure();
  await GetIt.I<ImageService>().ignorePermissions();
  var sendPort =
      IsolateNameServer.lookupPortByName(WorkManagerService.aiVectorPortName);
  await GetIt.I<VectorService>().syncVectors();
  sendPort?.send("CLEANED");
}

Future<void> handleAiProcessPeriodicTask() async {
  await Workmanager().registerOneOffTask(
    WorkManagerService.aiVectorTask,
    WorkManagerService.aiVectorTask,
    backoffPolicy: BackoffPolicy.linear,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(
      networkType: NetworkType.not_required,
    ),
  );
}

Future<void> handleAiVectorTask() async {
  await BackgroundStartup.configure();
  await GetIt.I<ImageService>().ignorePermissions();
  var sendPort =
      IsolateNameServer.lookupPortByName(WorkManagerService.aiVectorPortName);

  print("AI process started");
  sendPort?.send("STARTED");
  while (true) {
    sendPort =
        IsolateNameServer.lookupPortByName(WorkManagerService.aiVectorPortName);
    var result = await GetIt.I<VectorService>().procesNextImages();
    print("AI analysed completed for one image");

    if (!result) {
      break;
    }
    sendPort?.send("RUNNING");
  }
  print("AI analysed all the images");
  print("Reprocessing failed images");
  int offset = 0;
  while (true) {
    sendPort =
        IsolateNameServer.lookupPortByName(WorkManagerService.aiVectorPortName);
    var (hasNext, skipNext) =
        await GetIt.I<VectorService>().reprocessFailedImages(offset);

    if (!hasNext) {
      break;
    }
    sendPort?.send("RUNNING");
    if (skipNext) {
      offset++;
    }
  }
  print("Reprocessing failed images completed");
  sendPort?.send("COMPLETED");
}
