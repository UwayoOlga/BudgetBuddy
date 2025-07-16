import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final int userId;
  CalendarScreen({required this.userId});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> incomes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; });
    expenses = await DatabaseHelper.instance.getExpenses(widget.userId);
    incomes = await DatabaseHelper.instance.getIncomes(widget.userId);
    setState(() { loading = false; });
  }

  List<Map<String, dynamic>> getTransactionsForDay(DateTime day) {
    String d = DateFormat('yyyy-MM-dd').format(day);
    return [
      ...expenses.where((e) => DateFormat('yyyy-MM-dd').format(DateTime.parse(e['date'])) == d),
      ...incomes.where((i) => DateFormat('yyyy-MM-dd').format(DateTime.parse(i['date'])) == d),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Center(child: CircularProgressIndicator()) : Column(
      children: [
        SizedBox(height: 24),
        CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: DateTime(DateTime.now().year - 1),
          lastDate: DateTime(DateTime.now().year + 1),
          onDateChanged: (d) => setState(() => selectedDate = d),
        ),
        SizedBox(height: 16),
        Text('Transactions on ${DateFormat('yyyy-MM-dd').format(selectedDate)}', style: TextStyle(color: Color(0xFF6C2EB7), fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...getTransactionsForDay(selectedDate).map((t) => Card(
          color: t['amount'] > 0 ? Color(0xFF2D0146) : Colors.red[100],
          child: ListTile(
            title: Text(t['category'] ?? t['source'] ?? '', style: TextStyle(color: Colors.white)),
            subtitle: Text(t['description'] ?? t['notes'] ?? '', style: TextStyle(color: Colors.white70)),
            trailing: Text('${t['amount'] > 0 ? '+' : '-'}${t['amount'].toStringAsFixed(2)}', style: TextStyle(color: t['amount'] > 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        )),
        if (getTransactionsForDay(selectedDate).isEmpty)
          Text('No transactions', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
} 