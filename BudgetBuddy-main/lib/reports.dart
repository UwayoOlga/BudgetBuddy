import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'expense_model.dart';
import 'income_model.dart';
import 'budget_model.dart';
import 'savings_goal_model.dart';

class ReportsScreen extends StatefulWidget {
  final int userId;
  ReportsScreen({required this.userId});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String period = 'This Month';
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> savings = [];
  Map<String, double> categoryTotals = {};
  bool loading = true;
  String sortBy = 'date';
  String filterCategory = 'All';
  List<String> allCategories = ['All'];
  String filterPaymentMethod = 'All';
  List<String> allPaymentMethods = ['All'];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; });
    try {
      var expensesBox = Hive.box('expenses');
      var incomesBox = Hive.box('incomes');
      var budgetsBox = Hive.box('budgets');
      var savingsBox = Hive.box('savings');
      expenses = expensesBox.values.where((e) => e.userId == widget.userId).map((e) => {
        'amount': e.amount,
        'category': e.category,
        'date': e.date.toString(),
        'description': e.description,
        'paymentMethod': e.paymentMethod,
        'isRecurring': e.isRecurring,
        'object': e,
      }).toList();
      incomes = incomesBox.values.where((i) => i.userId == widget.userId).map((i) => {
        'amount': i.amount,
        'source': i.source,
        'date': i.date.toString(),
        'notes': i.notes,
        'object': i,
      }).toList();
      budgets = budgetsBox.values.where((b) => b.userId == widget.userId).map((b) => {
        'amount': b.amount,
        'category': b.category,
        'month': b.month,
        'period': b.period,
        'object': b,
      }).toList();
      savings = savingsBox.values.where((s) => s.userId == widget.userId).map((s) => {
        'targetAmount': s.targetAmount,
        'savedAmount': s.savedAmount,
        'name': s.name,
        'targetDate': s.targetDate,
        'object': s,
      }).toList();
      DateTime now = DateTime.now();
      DateTime start;
      if (period == 'This Month') {
        start = DateTime(now.year, now.month, 1);
      } else if (period == 'Last 7 Days') {
        start = now.subtract(Duration(days: 7));
      } else {
        start = DateTime(now.year, now.month, 1);
      }
      expenses = expenses.where((e) => DateTime.parse(e['date']).isAfter(start)).toList();
      allCategories = ['All'] + expenses.map((e) => e['category'] as String).toSet().toList();
      allPaymentMethods = ['All'] + expenses.map((e) => e['paymentMethod'] as String).toSet().toList();
      if (filterCategory != 'All') {
        expenses = expenses.where((e) => e['category'] == filterCategory).toList();
      }
      if (filterPaymentMethod != 'All') {
        expenses = expenses.where((e) => e['paymentMethod'] == filterPaymentMethod).toList();
      }
      if (sortBy == 'amount') {
        expenses.sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
      } else {
        expenses.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      }
      categoryTotals = {};
      for (var e in expenses) {
        categoryTotals[e['category']] = (categoryTotals[e['category']] ?? 0) + (e['amount'] ?? 0).toDouble();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load report data.')),
      );
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load report data: \n$e'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
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

  @override
  Widget build(BuildContext context) {
    final totalIncome = incomes.fold(0.0, (a, b) => a + (b['amount'] ?? 0));
    final totalExpenses = expenses.fold(0.0, (a, b) => a + (b['amount'] ?? 0));
    final profit = totalIncome - totalExpenses;
    return loading ? Center(child: CircularProgressIndicator()) : ListView(
      padding: EdgeInsets.all(24),
      children: [
        // PROFIT/LOSS SUMMARY
        Card(
          color: profit > 0 ? Colors.green[900] : (profit < 0 ? Colors.red[900] : Color(0xFF2D0146)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  profit > 0 ? Icons.trending_up : (profit < 0 ? Icons.trending_down : Icons.horizontal_rule),
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    profit > 0
                      ? 'Profit: +${profit.toStringAsFixed(2)}'
                      : (profit < 0
                        ? 'Loss: ${profit.toStringAsFixed(2)}'
                        : 'Break-even'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
            DropdownButton<String>(
              value: period,
              dropdownColor: Color(0xFF2D0146),
              style: TextStyle(color: Colors.white),
              items: ['This Month', 'Last 7 Days'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() { period = v!; loadData(); }),
            ),
          ],
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Filter:', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: filterCategory,
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
                items: allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() { filterCategory = v!; loadData(); }),
              ),
              SizedBox(width: 16),
              Text('Payment:', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: filterPaymentMethod,
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
                items: allPaymentMethods.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() { filterPaymentMethod = v!; loadData(); }),
              ),
              SizedBox(width: 16),
              Text('Sort by:', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: sortBy,
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
                items: [DropdownMenuItem(value: 'date', child: Text('Date')), DropdownMenuItem(value: 'amount', child: Text('Amount'))],
                onChanged: (v) => setState(() { sortBy = v!; loadData(); }),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Income: +${totalIncome.toStringAsFixed(2)}', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            Text('Total Expenses: -${totalExpenses.toStringAsFixed(2)}', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 16),
        Text('Budgets', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        ...budgets.map((b) => Card(
          color: Color(0xFF2D0146),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text('${b['category']} (${b['period']})', style: TextStyle(color: Colors.white)),
            subtitle: Text('Amount: ${b['amount'].toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
          ),
        )),
        SizedBox(height: 16),
        Text('Savings Goals', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        ...savings.map((s) => Card(
          color: Color(0xFF2D0146),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(s['name'], style: TextStyle(color: Colors.white)),
            subtitle: Text('Saved: ${s['savedAmount'].toStringAsFixed(2)} / ${s['targetAmount'].toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
            trailing: Text('Target: ${DateFormat('yyyy-MM-dd').format(s['targetDate'])}', style: TextStyle(color: Colors.white54)),
          ),
        )),
        SizedBox(height: 24),
        Text('Spending by Category', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        Container(
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
        Text('All Activities', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        ...(() {
          final allActivities = [
            ...incomes.map((i) => {'type': 'income', ...i}),
            ...expenses.map((e) => {'type': 'expense', ...e}),
            ...savings.map((s) => {'type': 'savings', ...s})
          ];
          allActivities.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
          return allActivities.map((t) => Card(
            color: t['type'] == 'income'
              ? Color(0xFF1A4D2E)
              : t['type'] == 'expense'
                ? Color(0xFF4B006E)
                : Color(0xFF2D0146),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(
                t['type'] == 'income'
                  ? Icons.arrow_downward
                  : t['type'] == 'expense'
                    ? Icons.arrow_upward
                    : Icons.savings,
                color: Colors.white,
              ),
              title: Text(
                t['type'] == 'income'
                  ? (t['source'] ?? '')
                  : t['type'] == 'expense'
                    ? (t['category'] ?? '')
                    : (t['name'] ?? ''),
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                t['type'] == 'income'
                  ? (t['notes'] ?? '')
                  : t['type'] == 'expense'
                    ? (t['description'] ?? '')
                    : 'Saved: ${(t['savedAmount'] ?? 0).toStringAsFixed(2)} / ${(t['targetAmount'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white70),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t['type'] == 'income')
                    Text('+' + (t['amount'] ?? 0).toStringAsFixed(2), style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  if (t['type'] == 'expense')
                    Text('-' + (t['amount'] ?? 0).toStringAsFixed(2), style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  if (t['type'] == 'savings')
                    Icon(Icons.savings, color: Colors.amberAccent),
                ],
              ),
            ),
          ));
        })(),
        if (incomes.isEmpty && expenses.isEmpty && savings.isEmpty)
          Text('No activities', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
} 