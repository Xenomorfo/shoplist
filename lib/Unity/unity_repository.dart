import 'package:sqflite/sqflite.dart';

import '../Database/database_provider.dart';
import '../Database/databasehelper.dart';
import '../actionloggerservice.dart';
import 'unity.dart';

final unityRepository = DatabaseProvider<Unity>(
  tableName: 'unities',
  fromMap: Unity.fromMap,
);

class UnityRepositoryService {
  final action = const ActionLoggerService();

  Future<List<Unity>> fetchUnities() =>
      unityRepository.queryAll(orderBy: 'name COLLATE NOCASE ASC');

  Future<int> addUnity(Unity unity) async {
    final id = await unityRepository.insert(unity);
    await action.addAction('+ Adicionou ${unity.name}');
    return id;
  }

  // Mantido para compatibilidade com o código antigo.
  Future<int> addCategory(Unity unity) => addUnity(unity);

  Future<Unity?> fetchOneUnity(int id) => unityRepository.queryById(id);

  Future<int> updateUnity(Unity unity) async {
    final result = await unityRepository.update(unity);
    if (result > 0) await action.addAction('~ Alterou ${unity.name}');
    return result;
  }

  Future<int> deleteUnity(int id) async {
    final database = await DatabaseHelper.instance.db;
    final itemCount = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM items WHERE unityId = ?', [id]),
        ) ??
        0;
    final historyCount = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM historyItems WHERE unityId = ?', [id]),
        ) ??
        0;

    if (itemCount + historyCount > 0) {
      throw StateError('Esta unidade está a ser utilizada e não pode ser apagada.');
    }

    final unity = await fetchOneUnity(id);
    final result = await unityRepository.delete(id);
    if (result > 0 && unity != null) {
      await action.addAction('- Apagou ${unity.name}');
    }
    return result;
  }
}

final unityRepoService = UnityRepositoryService();
