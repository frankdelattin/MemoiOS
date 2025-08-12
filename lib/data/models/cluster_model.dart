import 'package:snapp_app/data/models/base_model.dart';

class ClusterModel implements BaseModel {
  final int? id;
  final String name;
  final DateTime createdAt;

  ClusterModel({this.id, required this.name, required this.createdAt});

  @override
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "created_at": createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  factory ClusterModel.fromMap(Map<String, dynamic> map) {
    return ClusterModel(
      id: map["id"],
      name: map["name"],
      createdAt: DateTime.parse(map["created_at"]).toLocal(),
    );
  }
}
