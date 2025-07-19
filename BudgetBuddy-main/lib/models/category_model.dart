import 'package:hive/hive.dart';
part 'category_model.g.dart';

@HiveType(typeId: 10)
class Category extends HiveObject {
  @HiveField(0)
  int userId;
  @HiveField(1)
  String name;
  @HiveField(2)
  String type; // 'expense' or 'income'

  Category({required this.userId, required this.name, required this.type});
} 