import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../services/hive_service.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final int userId;
  const CalendarScreen({super.key, required this.userId});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final expenseBox = HiveService.getExpenseBox();
    final expenses = expenseBox.values.where((e) => e.userId == widget.userId).toList();
    Map<DateTime, List<Expense>> expenseMap = {};
    for (var e in expenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      expenseMap.putIfAbsent(day, () => []).add(e);
    }
    final selectedExpenses = _selectedDay == null
        ? []
        : expenseMap[_selectedDay!] ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFF2D0146),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D0146),
        elevation: 0,
        title: const Text('Calendar', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          TableCalendar<Expense>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              final d = DateTime(day.year, day.month, day.day);
              return expenseMap[d] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Color(0xFF6C2EB7), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              selectedTextStyle: TextStyle(color: Color(0xFF6C2EB7), fontWeight: FontWeight.bold),
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white70),
              outsideTextStyle: TextStyle(color: Colors.white24),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: selectedExpenses.isEmpty
                ? Center(child: Text('No expenses for this day.', style: TextStyle(color: Colors.white54)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedExpenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = selectedExpenses[i];
                      return ListTile(
                        tileColor: const Color(0xFF4B006E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: Icon(_categoryIcon(e.category), color: Colors.white),
                        title: Text(e.category, style: TextStyle(color: Colors.white)),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(e.date), style: TextStyle(color: Colors.white70)),
                        trailing: Text(NumberFormat.currency(symbol: ' RWF', decimalDigits: 2).format(e.amount), style: TextStyle(color: Colors.white)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_bus;
      case 'books':
        return Icons.menu_book;
      case 'fun':
        return Icons.celebration;
      case 'other':
        return Icons.category;
      default:
        return Icons.attach_money;
    }
  }
} 