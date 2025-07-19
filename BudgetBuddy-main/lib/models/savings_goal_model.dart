import 'package:hive_flutter/hive_flutter.dart';
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

  SavingsGoal({
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
  });

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
    userId: map['userId'] ?? -1,
    name: map['name'] ?? '',
    targetAmount: (map['targetAmount'] ?? 0).toDouble(),
    savedAmount: (map['savedAmount'] ?? 0).toDouble(),
    targetDate: map['targetDate'] is DateTime ? map['targetDate'] : DateTime.tryParse(map['targetDate'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'targetDate': targetDate.toIso8601String(),
  };
} 