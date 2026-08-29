import '../Database/database_provider.dart';
import '../Database/databasehelper.dart';
import 'list_item.dart';

final listItemRepository = DatabaseProvider<ListItem>(
  tableName: 'listItems',
  fromMap: ListItem.fromMap,
);

class ListItemRepositoryService {
  Future<List<ListItem>> fetchListItens() =>
      listItemRepository.queryAll(orderBy: 'id ASC');

  Future<int> addListItem(ListItem listItem) => listItemRepository.insert(listItem);

  Future<bool> addListItemIfMissing(ListItem listItem) async {
    if (listItem.listId == null || listItem.itemId == null) return false;
    final database = await DatabaseHelper.instance.db;
    final existing = await database.query(
      'listItems',
      columns: ['id'],
      where: 'listId = ? AND itemId = ?',
      whereArgs: [listItem.listId, listItem.itemId],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await listItemRepository.insert(listItem);
    await database.update(
      'lists',
      {'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [listItem.listId],
    );
    return true;
  }

  Future<List<ListItem>> fetchItemsByListId(int listId) async {
    final database = await DatabaseHelper.instance.db;
    final maps = await database.query(
      'listItems',
      where: 'listId = ?',
      whereArgs: [listId],
      orderBy: 'id ASC',
    );
    return maps.map(ListItem.fromMap).toList();
  }

  Future<int> updateListItem(ListItem listItem) => listItemRepository.update(listItem);

  Future<int> deleteListItem(int? id) async {
    if (id == null) return 0;
    return listItemRepository.delete(id);
  }

  Future<int> deleteItemsByListId(int listId) async {
    final database = await DatabaseHelper.instance.db;
    return database.delete('listItems', where: 'listId = ?', whereArgs: [listId]);
  }

  Future<int> addItemsToActiveList(List<ListItem> items) async {
    var added = 0;
    for (final item in items) {
      if (await addListItemIfMissing(item)) added++;
    }
    return added;
  }
}

final listItemRepoService = ListItemRepositoryService();
