import '../Database/database_provider.dart';
import '../Database/databasehelper.dart';
import '../actionloggerservice.dart';
import 'item.dart';

final itemRepository = DatabaseProvider<Item>(
  tableName: 'items',
  fromMap: Item.fromMap,
);

class ItemRepositoryService {
  final action = const ActionLoggerService();

  Future<List<Item>> fetchItens() =>
      itemRepository.queryAll(orderBy: 'name COLLATE NOCASE ASC');

  Future<int> addItem(Item item) async {
    final id = await itemRepository.insert(item);
    await action.addAction('+ Adicionou ${item.name ?? 'item'}');
    return id;
  }

  Future<Item?> fetchOneItem(int id) => itemRepository.queryById(id);

  Future<int> updateItem(Item item) async {
    final result = await itemRepository.update(item);
    if (result > 0) await action.addAction('~ Alterou ${item.name ?? 'item'}');
    return result;
  }

  Future<int> deleteItem(int id) async {
    final database = await DatabaseHelper.instance.db;
    final item = await fetchOneItem(id);

    final result = await database.transaction((txn) async {
      await txn.delete('listItems', where: 'itemId = ?', whereArgs: [id]);
      return txn.delete('items', where: 'id = ?', whereArgs: [id]);
    });

    if (result > 0 && item != null) {
      await action.addAction('- Apagou ${item.name ?? 'item'}');
    }
    return result;
  }
}

final itemRepoService = ItemRepositoryService();
