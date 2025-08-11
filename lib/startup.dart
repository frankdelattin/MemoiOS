import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/extensions/bloc_extension.dart';
import 'package:snapp_app/extensions/cache_extension.dart';
import 'package:snapp_app/extensions/database_extension.dart';
import 'package:snapp_app/extensions/plugin_extension.dart';
import 'package:snapp_app/extensions/repository_extension.dart';
import 'package:snapp_app/extensions/service_extension.dart';
import 'package:snapp_app/services/vector_service.dart';

class Startup {
  static Future configure() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _registerDependencies();
    
    // Clean up orphaned vectors after dependencies are ready
    await _cleanupOrphanedVectors();
  }

  static Future _registerDependencies() async {
    final getIt = GetIt.instance;
    getIt.registerDatabase();
    getIt.registerCache();

    getIt.registerPlugins();

    getIt.registerRepositories();
    getIt.registerServices();

    getIt.registerBlocs();

    await getIt.allReady();
  }

  static Future _cleanupOrphanedVectors() async {
    try {
      final vectorService = GetIt.instance<VectorService>();
      await vectorService.cleanupOrphanedVectors();
    } catch (e) {
      print('Failed to cleanup orphaned vectors during startup: $e');
      // Continue startup even if cleanup fails
    }
  }
}
