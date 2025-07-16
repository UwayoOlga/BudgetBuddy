import 'package:hive/hive.dart';
part 'budget_model.g.dart';

@HiveType(typeId: 3)
class Budget extends HiveObject {
  @HiveField(0)
  int userId;
  @HiveField(1)
  String month;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String category;
  @HiveField(4)
  String period;
  Budget({required this.userId, required this.month, required this.amount, required this.category, required this.period});
} 