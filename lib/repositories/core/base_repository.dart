import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:snapp_app/data/models/base_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class BaseRepository<T extends BaseModel> {
  @protected
  String get tableName;
  @protected
  ModelCreator<T> get creator;

  final Database _database;

  BaseRepository({required Database database}) : _database = database;

  Future<int> insert(T entity) async {
    return await _database.insert(tableName, entity.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertAll(List<T> entities) async {
    final batch = _database.batch();

    for (var entity in entities) {
      batch.insert(tableName, entity.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<void> updateById(int id, T entity) async {
    await _database
        .update(tableName, entity.toMap(), where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteById(int id) async {
    await _database.delete(tableName, where: "id = ?", whereArgs: [id]);
  }

  Future<T> findById(int id) async {
    final result = await findAllByQuery(condition: "id = ?", arguments: [id]);
    if (result.isNotEmpty) {
      return result.first;
    } else {
      throw Exception('Entity not found');
    }
  }

  Future<List<T>> findAll() async {
    return await findAllByQuery(limit: 1274);
  }

  Future rawQuery(String query, List<Object?> arguments) async {
    final result = await runQuery(query, arguments);
    print(result);
  }

  Future<List<T>> findAllByQuery({
    String? condition,
    List<Object?> arguments = const [],
    String? orderBy,
    int? limit,
    int? offset,
    bool? distinct,
  }) async {
    final result = await _database.query(
      tableName,
      where: condition,
      whereArgs: arguments,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      distinct: distinct,
    );
    return result.map((e) => creator(e)).toList();
  }

  Future<void> deleteAll() async {
    await _database.delete(tableName);
  }

  Future<int> count() async {
    final result = await runQuery("SELECT COUNT(*) FROM $tableName;", []);
    return result.first.values.first;
  }

  @protected
  Future<List<Map<String, dynamic>>> runQuery(
      String query, List<Object?> arguments) async {
    final result = await _database.rawQuery(query, arguments);
    return result;
  }
}
