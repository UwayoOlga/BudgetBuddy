import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'expense_model.dart';
import 'income_model.dart';

class CalendarScreen extends StatefulWidget {
  final int userId;
  CalendarScreen({required this.userId});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> incomes = [];
  bool loading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    loadData();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() { loading = true; });
    var expensesBox = Hive.box('expenses');
    var incomesBox = Hive.box('incomes');
    expenses = expensesBox.values.where((e) => e.userId == widget.userId).map((e) => {
      'amount': e.amount,
      'category': e.category,
      'date': e.date.toString(),
      'description': e.description,
      'paymentMethod': e.paymentMethod,
      'isRecurring': e.isRecurring,
      'object': e,
      'type': 'expense',
    }).toList();
    incomes = incomesBox.values.where((i) => i.userId == widget.userId).map((i) => {
      'amount': i.amount,
      'source': i.source,
      'date': i.date.toString(),
      'notes': i.notes,
      'object': i,
      'type': 'income',
    }).toList();
    setState(() { loading = false; });
  }

  List<Map<String, dynamic>> getTransactionsForDay(DateTime day) {
    String d = DateFormat('yyyy-MM-dd').format(day);
    return [
      ...expenses.where((e) => DateFormat('yyyy-MM-dd').format(DateTime.parse(e['date'])) == d),
      ...incomes.where((i) => DateFormat('yyyy-MM-dd').format(DateTime.parse(i['date'])) == d),
    ]..sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
  }

  void showEditDialog(Map<String, dynamic> t) {
    if (t['type'] == 'income') {
      // TODO: Implement edit income dialog
    } else {
      // TODO: Implement edit expense dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Center(child: CircularProgressIndicator())
        : FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                SizedBox(height: 24),
                CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime(DateTime.now().year + 1),
                  onDateChanged: (d) {
                    setState(() => selectedDate = d);
                    _controller.forward(from: 0);
                  },
                ),
                SizedBox(height: 16),
                Text('Transactions on ${DateFormat('yyyy-MM-dd').format(selectedDate)}', style: TextStyle(color: Color(0xFF6C2EB7), fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...getTransactionsForDay(selectedDate).map((t) => Card(
                      color: t['type'] == 'income' ? Color(0xFF1A4D2E) : Color(0xFF4B006E),
                      child: ListTile(
                        title: Text(t['type'] == 'income' ? t['source'] ?? '' : t['category'] ?? '', style: TextStyle(color: Colors.white)),
                        subtitle: Text(t['type'] == 'income' ? (t['notes'] ?? '') : (t['description'] ?? ''), style: TextStyle(color: Colors.white70)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text((t['type'] == 'income' ? '+' : '-') + (t['amount'] ?? 0).toStringAsFixed(2), style: TextStyle(color: t['type'] == 'income' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.white),
                              onPressed: () => showEditDialog(t),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.white),
                              onPressed: () async {
                                await t['object'].delete();
                                setState(() { loadData(); });
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
                if (getTransactionsForDay(selectedDate).isEmpty)
                  Text('No transactions', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
  }
} 