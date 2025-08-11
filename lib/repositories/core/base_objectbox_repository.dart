import 'package:flutter/foundation.dart';
import 'package:snapp_app/data/models/base_box.dart';
import 'package:snapp_app/objectbox.g.dart';

class BaseObjectBoxRepository<T extends BaseBox> {
  final Store _objectStore;

  BaseObjectBoxRepository({required Store objectStore})
      : _objectStore = objectStore;

  Future<int> count() async {
    return _objectStore.box<T>().count();
  }

  Future<int> insert(T entity) async {
    return await _objectStore.box<T>().putAsync(entity);
  }

  Future<void> insertAll(List<T> entities) async {
    await _objectStore.box<T>().putManyAsync(entities);
  }

  Future<void> delete(int id) async {
    await _objectStore.box<T>().removeAsync(id);
  }

  Future<void> deleteAll() async {
    await _objectStore.box<T>().removeAllAsync();
  }

  Future<List<T>> getAll() async {
    return await _objectStore.box<T>().getAllAsync();
  }

  Future<T?> getById(int id) async {
    return await _objectStore.box<T>().getAsync(id);
  }

  Future<void> update(T entity) async {
    await _objectStore.box<T>().putAsync(entity);
  }

  Future<void> updateAll(List<T> entities) async {
    await _objectStore.box<T>().putManyAsync(entities);
  }

  @protected
  int countByQuery(Condition<T> condition) {
    return _objectStore.box<T>().query(condition).build().count();
  }

  @protected
  Future<List<T>> query(
      {Condition<T>? condition,
      QueryProperty<T, dynamic>? orderBy,
      int order = 0,
      int? limit,
      int? offset}) async {
    var builder = _objectStore.box<T>().query(condition);

    if (orderBy != null) {
      builder = builder.order(orderBy, flags: order);
    }

    var query = builder.build();
    if (limit != null) {
      query.limit = limit;
    }
    if (offset != null) {
      query.offset = offset;
    }
    return await query.findAsync();
  }

  Future<void> deleteByQuery({Condition<T>? condition}) async {
    await _objectStore.box<T>().query(condition).build().removeAsync();
  }

  Future<List<ObjectWithScore<T>>> queryWithScores(
      {required Condition<T> condition, int? limit}) async {
    var query = _objectStore.box<T>().query(condition).build();
    if (limit != null) {
      query.limit = limit;
    }
    return await query.findWithScoresAsync();
  }
}
