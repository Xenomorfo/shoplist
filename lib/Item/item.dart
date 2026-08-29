import '../data_model.dart';

class Item implements DataModel {
  @override
  final int? id;
  final int? listId;
  final String? name;
  final double? qty;
  final int? unityId;
  final int? categoryId;
  final bool isBought;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  String get tableName => 'items';

  const Item({
    this.id,
    this.listId,
    required this.name,
    required this.qty,
    required this.unityId,
    required this.categoryId,
    this.isBought = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      listId: map['listId'] as int?,
      name: map['name'] as String?,
      qty: _doubleFromDb(map['qty']),
      unityId: map['unityId'] as int?,
      categoryId: map['categoryId'] as int?,
      isBought: _boolFromDb(map['isBought']),
      notes: map['notes'] as String?,
      createdAt: _dateFromDb(map['createdAt']),
      updatedAt: _dateFromDb(map['updatedAt']),
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

  static DateTime? _dateFromDb(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'name': name?.trim(),
      'qty': qty,
      'unityId': unityId,
      'categoryId': categoryId,
      'isBought': isBought ? 1 : 0,
      'notes': notes?.trim(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
