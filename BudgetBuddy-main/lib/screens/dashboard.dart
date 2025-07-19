import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../services/hive_service.dart';
import 'package:intl/intl.dart';
import '../services/notifications.dart';

class DashboardScreen extends StatelessWidget {
  final int userId;
  const DashboardScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0146),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D0146),
        elevation: 0,
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/settings', arguments: userId),
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Expense>('expenses').listenable(),
        builder: (context, Box<Expense> expensesBox, _) {
          final sessionBox = HiveService.getSessionBox();
          final currency = sessionBox.get('currency', defaultValue: 'RWF');
          final remindersEnabled = sessionBox.get('remindersEnabled', defaultValue: true);
          final expenses = expensesBox.values.where((e) => e.userId == userId).toList();
          final now = DateTime.now();
          final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
          final budgetsBox = Hive.box<Budget>('budgets');
          final budgetData = budgetsBox.values.firstWhere(
            (b) => b.userId == userId && b.month == month,
            orElse: () => Budget.defaultBudget(),
          );
          final budget = budgetData.amount;
          double spent = 0;
          Map<String, double> categoryTotals = {};
          for (var e in expenses) {
            spent += e.amount;
            categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
          }
          final balance = budget - spent;
          String? budgetWarning;
          if (remindersEnabled && budget > 0 && spent / budget >= 0.8) {
            budgetWarning = 'Warning: You have spent 80% or more of your budget!';
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (budgetWarning != null)
                  NotificationsBanner(budgetWarning: budgetWarning),
                Text('Hello!', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Here is your financial overview.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                // Currency label above the row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(currency, style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B006E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budget', style: TextStyle(color: Colors.white70)),
                          Text(NumberFormat.currency(symbol: '', decimalDigits: 2).format(budget), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Spent', style: TextStyle(color: Colors.white70)),
                          Text(NumberFormat.currency(symbol: '', decimalDigits: 2).format(spent), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Balance', style: TextStyle(color: Colors.white70)),
                          Text(NumberFormat.currency(symbol: '', decimalDigits: 2).format(balance), style: TextStyle(color: balance >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Spending by Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B006E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: categoryTotals.isEmpty
                    ? Center(child: Text('No expenses yet.', style: TextStyle(color: Colors.white54)))
                    : PieChart(
                        PieChartData(
                          sections: categoryTotals.entries.map((e) => PieChartSectionData(
                            color: Colors.primaries[e.key.hashCode % Colors.primaries.length],
                            value: e.value,
                            title: e.key,
                            titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                        ),
                      ),
                ),
                const SizedBox(height: 24),
                Text('Recent Expenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...expenses.take(5).map((e) => ListTile(
                  tileColor: const Color(0xFF4B006E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text(e.category, style: TextStyle(color: Colors.white)),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(e.date), style: TextStyle(color: Colors.white70)),
                  trailing: Text(NumberFormat.currency(symbol: ' ' + currency, decimalDigits: 2).format(e.amount), style: TextStyle(color: Colors.white)),
                )),
                if (expenses.isEmpty)
                  Center(child: Text('No expenses yet.', style: TextStyle(color: Colors.white54))),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2EB7)),
                      onPressed: () => Navigator.pushNamed(context, '/add', arguments: userId),
                      icon: const Icon(Icons.list, color: Colors.white),
                      label: const Text('All Expenses', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2EB7)),
                      onPressed: () => Navigator.pushNamed(context, '/reports', arguments: userId),
                      icon: const Icon(Icons.bar_chart, color: Colors.white),
                      label: const Text('Reports', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 