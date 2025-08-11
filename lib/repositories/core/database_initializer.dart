import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInitializer {
  static const _databaseName = "snapp_app.db";
  static const _initScript = "assets/sql/init_database.sql";

  Future<Database> get instance async {
    return await openDatabase(join((await getDatabasesPath()), _databaseName),
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
        version: 1,
        singleInstance: true);
  }

  FutureOr<void> _createDatabase(Database db, int version) async {
    var sql = await rootBundle.loadString(_initScript);

    sql.split(";").forEach((sql) {
      db.execute(sql);
    });
  }

  FutureOr<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) {}
}
