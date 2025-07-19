import 'package:hive_flutter/hive_flutter.dart';
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

  Expense({
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    required this.isRecurring,
  });

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    userId: map['userId'] ?? -1,
    amount: (map['amount'] ?? 0).toDouble(),
    category: map['category'] ?? '',
    date: map['date'] is DateTime ? map['date'] : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    description: map['description'] ?? '',
    paymentMethod: map['paymentMethod'] ?? '',
    isRecurring: map['isRecurring'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'description': description,
    'paymentMethod': paymentMethod,
    'isRecurring': isRecurring,
  };
} 