import 'package:flutter_test/flutter_test.dart';
import 'package:shoplist/Category/category.dart';
import 'package:shoplist/History_Items/historyitem.dart';
import 'package:shoplist/Item/item.dart';
import 'package:shoplist/Shopping/list_item.dart';

void main() {
  group('SQLite model mapping', () {
    test('Item accepts integer quantities and boolean integers', () {
      final item = Item.fromMap({
        'id': 10,
        'listId': null,
        'name': 'Leite',
        'qty': 2,
        'unityId': 2,
        'categoryId': 4,
        'isBought': 1,
        'notes': null,
        'createdAt': '2026-08-29T10:00:00.000',
        'updatedAt': '2026-08-29T10:00:00.000',
      });

      expect(item.qty, 2.0);
      expect(item.isBought, isTrue);
    });

    test('HistoryItem reads wasBought instead of the old isBought key', () {
      final item = HistoryItem.fromMap({
        'id': 1,
        'listHistoryId': 2,
        'name': 'Pão',
        'qty': 1,
        'unityId': 5,
        'categoryId': 14,
        'wasBought': 1,
      });

      expect(item.qty, 1.0);
      expect(item.wasBought, isTrue);
      expect(item.tableName, 'historyItems');
    });

    test('ListItem accepts SQLite numeric values safely', () {
      final item = ListItem.fromMap({
        'id': 3,
        'listId': 1,
        'itemId': 8,
        'qty': 6,
        'notes': '',
        'isChecked': 0,
      });

      expect(item.qty, 6.0);
      expect(item.isChecked, isFalse);
    });

    test('Category preserves visual metadata and active state', () {
      final category = Category.fromMap({
        'id': 4,
        'name': 'Laticínios',
        'icon': 'milk',
        'color': '#ffffff',
        'isActive': 0,
      });

      expect(category.icon, 'milk');
      expect(category.color, '#ffffff');
      expect(category.isActive, isFalse);
    });
  });
}
