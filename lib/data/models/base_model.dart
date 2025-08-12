abstract class BaseModel {
  Map<String, dynamic> toMap();

  factory BaseModel.fromMap(Map<String, dynamic> map) =>
      throw UnimplementedError();
}

typedef ModelCreator<T extends BaseModel> = T Function(Map<String, dynamic>);
