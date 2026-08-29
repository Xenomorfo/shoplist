abstract class DataModel {
  String get tableName;
  int? get id;
  Map<String, dynamic> toMap();
}
