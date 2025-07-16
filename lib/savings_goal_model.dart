import 'package:hive/hive.dart';
part 'savings_goal_model.g.dart';

@HiveType(typeId: 4)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  int userId;
  @HiveField(1)
  String name;
  @HiveField(2)
  double targetAmount;
  @HiveField(3)
  double savedAmount;
  @HiveField(4)
  DateTime targetDate;
  SavingsGoal({required this.userId, required this.name, required this.targetAmount, required this.savedAmount, required this.targetDate});
} 