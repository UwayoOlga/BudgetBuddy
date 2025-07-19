import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../services/hive_service.dart';

class CalendarScreen extends StatefulWidget {
  final int userId;
  const CalendarScreen({super.key, required this.userId});
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
    try {
      var expensesBox = HiveService.getExpenseBox();
      var incomesBox = HiveService.getIncomeBox();
      try {
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
      } catch (e) {
        expenses = [];
      }
      try {
        incomes = incomesBox.values.where((i) => i.userId == widget.userId).map((i) => {
          'amount': i.amount,
          'source': i.source,
          'date': i.date.toString(),
          'notes': i.notes,
          'object': i,
          'type': 'income',
        }).toList();
      } catch (e) {
        incomes = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load calendar data: $e')),
      );
    }
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
      final Income income = t['object'] as Income;
      final amountController = TextEditingController(text: income.amount.toString());
      final sourceController = TextEditingController(text: income.source);
      final notesController = TextEditingController(text: income.notes);
      DateTime date = income.date;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2D0146),
          title: const Text('Edit Income', style: TextStyle(color: Color(0xFF6C2EB7))),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Amount'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sourceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Source'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Notes'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2EB7)),
                  onPressed: () async {
                    try {
                      double? amt = double.tryParse(amountController.text);
                      if (amt == null || sourceController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount and source.')),
                        );
                        return;
                      }
                      income.amount = amt;
                      income.source = sourceController.text.trim();
                      income.notes = notesController.text.trim();
                      await income.save();
                      Navigator.pop(context);
                      setState(() {});
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('Failed to save income: \n$e'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final Expense expense = t['object'] as Expense;
      final amountController = TextEditingController(text: expense.amount.toString());
      final descController = TextEditingController(text: expense.description);
      String category = expense.category;
      String paymentMethod = expense.paymentMethod;
      bool isRecurring = expense.isRecurring;
      DateTime date = expense.date;
      final categories = ['Food', 'Transport', 'Books', 'Fun', 'Other'];
      final paymentMethods = ['Cash', 'Debit Card', 'Mobile Money'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2D0146),
          title: const Text('Edit Expense', style: TextStyle(color: Color(0xFF6C2EB7))),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Amount'),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: category,
                  dropdownColor: const Color(0xFF2D0146),
                  style: const TextStyle(color: Colors.white),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v!,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: paymentMethod,
                  dropdownColor: const Color(0xFF2D0146),
                  style: const TextStyle(color: Colors.white),
                  items: paymentMethods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => paymentMethod = v!,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: isRecurring,
                      onChanged: (v) => isRecurring = v ?? false,
                    ),
                    const Text('Recurring', style: TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2EB7)),
                  onPressed: () async {
                    try {
                      double? amt = double.tryParse(amountController.text);
                      if (amt == null || category.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount and category.')),
                        );
                        return;
                      }
                      expense.amount = amt;
                      expense.category = category;
                      expense.description = descController.text;
                      expense.paymentMethod = paymentMethod;
                      expense.isRecurring = isRecurring;
                      await expense.save();
                      Navigator.pop(context);
                      setState(() {});
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('Failed to save expense: \n$e'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: 24),
                CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime(DateTime.now().year + 1),
                  onDateChanged: (d) {
                    setState(() => selectedDate = d);
                    _controller.forward(from: 0);
                  },
                ),
                const SizedBox(height: 16),
                Text('Transactions on ${DateFormat('yyyy-MM-dd').format(selectedDate)}', style: const TextStyle(color: Color(0xFF6C2EB7), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...getTransactionsForDay(selectedDate).map((t) => Card(
                      color: t['type'] == 'income' ? const Color(0xFF1A4D2E) : const Color(0xFF4B006E),
                      child: ListTile(
                        title: Text(t['type'] == 'income' ? t['source'] ?? '' : t['category'] ?? '', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(t['type'] == 'income' ? (t['notes'] ?? '') : (t['description'] ?? ''), style: const TextStyle(color: Colors.white70)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text((t['type'] == 'income' ? '+' : '-') + (t['amount'] ?? 0).toStringAsFixed(2), style: TextStyle(color: t['type'] == 'income' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => showEditDialog(t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
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
                  const Text('No transactions', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
  }
} 