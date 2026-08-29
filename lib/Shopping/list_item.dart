import '../data_model.dart';

class ListItem implements DataModel {
  @override
  final int? id;
  final int? listId;
  final int? itemId;
  final double? qty;
  bool isChecked;
  final String? notes;

  @override
  String get tableName => 'listItems';

  ListItem({
    this.id,
    this.listId,
    this.itemId,
    this.qty,
    this.notes,
    this.isChecked = false,
  });

  factory ListItem.fromMap(Map<String, dynamic> map) {
    return ListItem(
      id: map['id'] as int?,
      listId: map['listId'] as int?,
      itemId: map['itemId'] as int?,
      qty: _doubleFromDb(map['qty']),
      notes: map['notes'] as String?,
      isChecked: _boolFromDb(map['isChecked']),
    );
  }

  static double? _doubleFromDb(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool _boolFromDb(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'itemId': itemId,
      'qty': qty,
      'notes': notes?.trim(),
      'isChecked': isChecked ? 1 : 0,
    };
  }
}
