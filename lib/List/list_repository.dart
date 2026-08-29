import '../Database/database_provider.dart';
import '../Database/databasehelper.dart';
import '../actionloggerservice.dart';
import 'list.dart';

final listyRepository = DatabaseProvider<Listy>(
  tableName: 'lists',
  fromMap: Listy.fromMap,
);

class ListyRepositoryService {
  final action = const ActionLoggerService();

  Future<List<Listy>> fetchLists() =>
      listyRepository.queryAll(orderBy: 'updatedAt DESC, id DESC');

  Future<int> addList(Listy list) async {
    final id = await listyRepository.insert(list);
    await action.addAction('+ Adicionou ${list.name}');
    return id;
  }

  Future<Listy?> fetchOneList(int id) => listyRepository.queryById(id);

  Future<int> updateList(Listy list) async {
    final result = await listyRepository.update(list);
    if (result > 0) await action.addAction('~ Alterou ${list.name}');
    return result;
  }

  Future<int> deleteList(int id) async {
    final database = await DatabaseHelper.instance.db;
    final list = await fetchOneList(id);

    final result = await database.transaction((txn) async {
      await txn.delete('listItems', where: 'listId = ?', whereArgs: [id]);
      await txn.update('items', {'listId': null}, where: 'listId = ?', whereArgs: [id]);
      return txn.delete('lists', where: 'id = ?', whereArgs: [id]);
    });

    if (result > 0 && list != null) {
      await action.addAction('- Apagou ${list.name}');
    }
    return result;
  }
}

final listyRepoService = ListyRepositoryService();
