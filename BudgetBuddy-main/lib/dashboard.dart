import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:hive/hive.dart';
import 'expense_model.dart';
import 'budget_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  DashboardScreen({required this.userId});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalBalance = 0;
  double budget = 0;
  double spent = 0;
  Map<String, double> categoryTotals = {};
  List<Map<String, dynamic>> recentExpenses = [];
  List<Expense> recentExpenseObjects = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      var expensesBox = Hive.box<Expense>('expenses');
      var expenses = expensesBox.values.where((e) {
        try {
          return e.userId == widget.userId;
        } catch (err) {
          print('Expense missing userId: ' + e.toString());
          return false;
        }
      }).toList();
      var now = DateTime.now();
      var month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      var budgetsBox = Hive.box<Budget>('budgets');
      var budgetData = budgetsBox.values.firstWhere(
        (b) {
          try {
            return b.userId == widget.userId && b.month == month;
          } catch (err) {
            print('Budget missing userId/month: ' + b.toString());
            return false;
          }
        },
        orElse: () => Budget.defaultBudget(),
      );
      budget = budgetData != null ? (budgetData.amount ?? 0) : 0;
      spent = 0;
      totalBalance = 0;
      categoryTotals = {};
      for (var e in expenses) {
        double amt = 0;
        try {
          amt = (e.amount ?? 0).toDouble();
        } catch (err) {
          print('Expense missing amount: ' + e.toString());
        }
        spent += amt;
        var cat = '';
        try {
          cat = e.category ?? '';
        } catch (err) {
          print('Expense missing category: ' + e.toString());
        }
        if (cat.isNotEmpty) {
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
        }
      }
      totalBalance = budget - spent;
      recentExpenseObjects = expenses.take(5).toList();
      recentExpenses = recentExpenseObjects.map((e) => {
        'amount': e.amount,
        'category': e.category,
        'date': e.date.toString(),
        'description': e.description,
        'paymentMethod': e.paymentMethod,
        'isRecurring': e.isRecurring,
      }).toList();
    } catch (e, st) {
      print('Error loading dashboard data: $e\n$st');
      errorMessage = 'Failed to load dashboard data. Please check your data.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data.')),
      );
    } finally {
      setState(() { loading = false; });
    }
  }

  List<PieChartSectionData> getPieSections() {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final colors = [Color(0xFF6C2EB7), Color(0xFFB388FF), Color(0xFF9575CD), Color(0xFFCE93D8), Color(0xFFF5F5F5)];
    int i = 0;
    return categoryTotals.entries.map((e) {
      final percent = total == 0 ? 0 : (e.value / total * 100).round();
      return PieChartSectionData(
        color: colors[i++ % colors.length],
        value: e.value,
        title: percent > 0 ? '${percent}%' : '',
        radius: 48,
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      );
    }).toList();
  }

  void showEditExpenseDialog(Expense expense) {
    double amount = expense.amount;
    String category = expense.category;
    DateTime date = expense.date;
    String description = expense.description;
    String paymentMethod = expense.paymentMethod;
    bool isRecurring = expense.isRecurring;
    final categories = ['Food', 'Transport', 'Books', 'Fun', 'Other'];
    final paymentMethods = ['Cash', 'Debit Card', 'Mobile Money'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D0146),
        title: Text('Edit Expense', style: TextStyle(color: Color(0xFF6C2EB7))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = double.tryParse(v) ?? 0,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Amount'),
                controller: TextEditingController(text: expense.amount.toString()),
              ),
              SizedBox(height: 8),
              DropdownButton<String>(
                value: category,
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v!,
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Color(0xFF6C2EB7),
                            onPrimary: Colors.white,
                            surface: Color(0xFF2D0146),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => date = picked);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4B006E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(date), style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                onChanged: (v) => description = v,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Description'),
                controller: TextEditingController(text: expense.description),
              ),
              SizedBox(height: 8),
              DropdownButton<String>(
                value: paymentMethod,
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
                items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => paymentMethod = v!,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isRecurring,
                    onChanged: (v) => isRecurring = v ?? false,
                    activeColor: Color(0xFF6C2EB7),
                  ),
                  Text('Recurring expense', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
            onPressed: () async {
              expense.amount = amount;
              expense.category = category;
              expense.date = date;
              expense.description = description;
              expense.paymentMethod = paymentMethod;
              expense.isRecurring = isRecurring;
              await expense.save();
              Navigator.pop(context);
              await loadData();
            },
            child: Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void deleteExpense(Expense expense) async {
    await expense.delete();
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: loadData,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: ListView(
          key: ValueKey(totalBalance + spent + categoryTotals.length),
          padding: EdgeInsets.all(24),
          children: [
            Text('Current Balance', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            AnimatedContainer(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF2D0146),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 500),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7)),
                    child: Text(totalBalance.toStringAsFixed(2)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Budget', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      SizedBox(height: 4),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(0xFF4B006E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: budget == 0 ? 0 : (spent / budget).clamp(0, 1),
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFFB388FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(' 0$spent spent / $budget', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('Spending by Category', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            AnimatedContainer(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              height: 160,
              decoration: BoxDecoration(
                color: Color(0xFF2D0146),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: categoryTotals.isEmpty
                  ? Text('No data', style: TextStyle(color: Colors.white54))
                  : PieChart(
                      PieChartData(
                        sections: getPieSections(),
                        centerSpaceRadius: 32,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
              ),
            ),
            SizedBox(height: 24),
            Text('Recent Expenses', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            ...recentExpenseObjects.map((e) => ListTile(
              leading: Icon(Icons.circle, color: Color(0xFF6C2EB7)),
              title: Text(e.category, style: TextStyle(color: Colors.white)),
              subtitle: Text(e.description, style: TextStyle(color: Colors.white70)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white70),
                    onPressed: () => showEditExpenseDialog(e),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => deleteExpense(e),
                  ),
                  Text('-${e.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            if (recentExpenseObjects.isEmpty)
              Text('No recent expenses', style: TextStyle(color: Colors.white54)),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C2EB7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/add', arguments: widget.userId),
                  icon: Icon(Icons.add),
                  label: Text('Add Expense', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4B006E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/reports'),
                  icon: Icon(Icons.bar_chart),
                  label: Text('Reports', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 