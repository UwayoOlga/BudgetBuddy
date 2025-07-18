import 'package:hive/hive.dart';
part 'income_model.g.dart';

@HiveType(typeId: 2)
class Income extends HiveObject {
  @HiveField(0)
  int userId;
  @HiveField(1)
  double amount;
  @HiveField(2)
  String source;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  String notes;
  Income({required this.userId, required this.amount, required this.source, required this.date, required this.notes});

  static Income fromMap(Map<String, dynamic> map) {
    return Income(
      userId: map['userId'] ?? -1,
      amount: (map['amount'] ?? 0).toDouble(),
      source: map['source'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
} 