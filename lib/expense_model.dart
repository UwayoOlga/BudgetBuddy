import 'package:hive/hive.dart';
part 'expense_model.g.dart';

@HiveType(typeId: 1)
class Expense extends HiveObject {
  @HiveField(0)
  int userId;
  @HiveField(1)
  double amount;
  @HiveField(2)
  String category;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  String description;
  @HiveField(5)
  String paymentMethod;
  @HiveField(6)
  bool isRecurring;
  Expense({required this.userId, required this.amount, required this.category, required this.date, required this.description, required this.paymentMethod, required this.isRecurring});
} 