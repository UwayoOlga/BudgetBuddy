import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'expense_model.dart';
import 'income_model.dart';

class ReportsScreen extends StatefulWidget {
  final int userId;
  ReportsScreen({required this.userId});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String period = 'This Month';
  List<Map<String, dynamic>> expenses = [];
  Map<String, double> categoryTotals = {};
  bool loading = true;
  String sortBy = 'date';
  String filterCategory = 'All';
  List<String> allCategories = ['All'];
  List<Map<String, dynamic>> incomes = [];
  String filterPaymentMethod = 'All';
  List<String> allPaymentMethods = ['All'];

  @override
  void initState() {
    super.initState();
    loadData();
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
    }).toList();
    incomes = incomesBox.values.where((i) => i.userId == widget.userId).map((i) => {
      'amount': i.amount,
      'source': i.source,
      'date': i.date.toString(),
      'notes': i.notes,
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
    setState(() { loading = false; });
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
    return loading ? Center(child: CircularProgressIndicator()) : ListView(
      padding: EdgeInsets.all(24),
      children: [
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
        // Replace the filter Row with a horizontally scrollable Row
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
            Text('Total Income: +${incomes.fold(0.0, (a, b) => a + (b['amount'] ?? 0)).toStringAsFixed(2)}', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            Text('Total Expenses: -${expenses.fold(0.0, (a, b) => a + (b['amount'] ?? 0)).toStringAsFixed(2)}', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
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
        Text('Transactions', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        ...expenses.map((e) => ListTile(
          leading: Icon(Icons.circle, color: Color(0xFF6C2EB7)),
          title: Text(e['category'] ?? '', style: TextStyle(color: Colors.white)),
          subtitle: Text('${e['description'] ?? ''} - ${DateFormat('yyyy-MM-dd').format(DateTime.parse(e['date']))}', style: TextStyle(color: Colors.white70)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('-${e['amount'].toStringAsFixed(2)}', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white70, size: 20),
                onPressed: () {
                  // TODO: Implement edit expense dialog
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                onPressed: () async {
                  // TODO: Implement delete expense
                },
              ),
            ],
          ),
        )),
        if (expenses.isEmpty)
          Text('No transactions', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
} 