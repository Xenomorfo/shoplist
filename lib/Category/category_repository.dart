import 'package:sqflite/sqflite.dart';

import '../Database/database_provider.dart';
import '../Database/databasehelper.dart';
import '../actionloggerservice.dart';
import 'category.dart';

final categoryRepository = DatabaseProvider<Category>(
  tableName: 'categories',
  fromMap: Category.fromMap,
);

class CategoryRepositoryService {
  final action = const ActionLoggerService();

  Future<List<Category>> fetchCategories() =>
      categoryRepository.queryAll(orderBy: 'name COLLATE NOCASE ASC');

  Future<int> addCategory(Category category) async {
    final id = await categoryRepository.insert(category);
    await action.addAction('+ Adicionou ${category.name}');
    return id;
  }

  Future<Category?> fetchOneCategory(int id) => categoryRepository.queryById(id);

  Future<int> updateCategory(Category category) async {
    final result = await categoryRepository.update(category);
    if (result > 0) await action.addAction('~ Alterou ${category.name}');
    return result;
  }

  Future<int> deleteCategory(int id) async {
    final database = await DatabaseHelper.instance.db;
    final itemCount = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM items WHERE categoryId = ?', [id]),
        ) ??
        0;
    final historyCount = Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT COUNT(*) FROM historyItems WHERE categoryId = ?',
            [id],
          ),
        ) ??
        0;

    if (itemCount + historyCount > 0) {
      throw StateError('Esta categoria está a ser utilizada e não pode ser apagada.');
    }

    final category = await fetchOneCategory(id);
    final result = await categoryRepository.delete(id);
    if (result > 0 && category != null) {
      await action.addAction('- Apagou ${category.name}');
    }
    return result;
  }
}

final categoryRepoService = CategoryRepositoryService();
