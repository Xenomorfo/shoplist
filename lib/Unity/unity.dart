import '../data_model.dart';

class Unity implements DataModel {
  @override
  final int? id;
  final String name;
  final String acronym;
  final String type;

  @override
  String get tableName => 'unities';

  const Unity({
    this.id,
    required this.name,
    required this.acronym,
    required this.type,
  });

  factory Unity.fromMap(Map<String, dynamic> map) {
    return Unity(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      acronym: (map['acronym'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'Unidade',
    );
  }

  @override
  bool operator ==(Object other) => other is Unity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'acronym': acronym.trim(),
      'type': type.trim(),
    };
  }
}
