import 'package:get_it/get_it.dart';
import 'package:snapp_app/repositories/core/database_initializer.dart';
import 'package:snapp_app/repositories/core/objectbox_initializer.dart';
import 'package:sqflite/sqflite.dart';

import '../objectbox.g.dart';

extension DatabaseDependencyExtension on GetIt {
  void registerDatabase() async {
    registerSingletonAsync<Database>(() => DatabaseInitializer().instance);
    registerSingletonAsync<Store>(() => ObjectBoxInitializer().instance);
  }
}
