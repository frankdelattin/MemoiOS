import 'package:get_it/get_it.dart';
import 'package:snapp_app/background/work_manager_service.dart';

class BackgroundServiceInitializer {
  static void initializeAll() {
    GetIt.I<WorkManagerService>().initialize();
  }
}
