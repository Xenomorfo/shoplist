import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'databasehelper.dart';
import '../data_model.dart';

class DatabaseProvider<T extends DataModel> {
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;

  const DatabaseProvider({required this.tableName, required this.fromMap});

  Future<Database> get db async => DatabaseHelper.instance.db;

  Future<int> insert(T model) async {
    final database = await db;
    final values = Map<String, dynamic>.from(model.toMap())..remove('id');
    return database.insert(tableName, values);
  }

  Future<List<T>> queryAll({String? orderBy}) async {
    final database = await db;
    final maps = await database.query(tableName, orderBy: orderBy);
    return maps.map(fromMap).toList();
  }

  Future<T?> queryById(int id) async {
    final database = await db;
    final maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : fromMap(maps.first);
  }

  Future<int> update(T model) async {
    if (model.id == null) return 0;
    final database = await db;
    final values = Map<String, dynamic>.from(model.toMap())..remove('id');
    return database.update(
      tableName,
      values,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final database = await db;
    return database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
