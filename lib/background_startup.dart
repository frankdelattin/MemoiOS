import 'dart:ui';

import 'package:get_it/get_it.dart';
import 'package:snapp_app/extensions/cache_extension.dart';
import 'package:snapp_app/extensions/database_extension.dart';
import 'package:snapp_app/extensions/plugin_extension.dart';
import 'package:snapp_app/extensions/repository_extension.dart';
import 'package:snapp_app/extensions/service_extension.dart';

class BackgroundStartup {
  static Future configure() async {
    DartPluginRegistrant.ensureInitialized();
    await _registerDependencies();
  }

  static Future _registerDependencies() async {
    final getIt = GetIt.instance;
    getIt.registerDatabase();
    getIt.registerCache();

    getIt.registerPluginsForBackground();
    getIt.registerRepositoriesForBackground();
    getIt.registerServicesForBackground();

    await getIt.allReady();
  }
}
