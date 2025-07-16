import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'dart:math';

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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; });
    await DatabaseHelper.instance.autoAddRecurringExpenses(widget.userId, DateTime.now());
    var expenses = await DatabaseHelper.instance.getExpenses(widget.userId);
    var now = DateTime.now();
    var month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    var budgetData = await DatabaseHelper.instance.getBudget(widget.userId, month);
    budget = budgetData != null ? (budgetData['amount'] ?? 0) : 0;
    spent = 0;
    totalBalance = 0;
    categoryTotals = {};
    for (var e in expenses) {
      double amt = (e['amount'] ?? 0).toDouble();
      spent += amt;
      categoryTotals[e['category']] = (categoryTotals[e['category']] ?? 0) + amt;
    }
    totalBalance = budget - spent;
    recentExpenses = expenses.take(5).toList();
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
    return loading ? Center(child: CircularProgressIndicator()) : RefreshIndicator(
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
            ...recentExpenses.map((e) => ListTile(
              leading: Icon(Icons.circle, color: Color(0xFF6C2EB7)),
              title: Text(e['category'] ?? '', style: TextStyle(color: Colors.white)),
              subtitle: Text(e['description'] ?? '', style: TextStyle(color: Colors.white70)),
              trailing: Text('-${e['amount'].toStringAsFixed(2)}', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            )),
            if (recentExpenses.isEmpty)
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
                  onPressed: () => Navigator.pushNamed(context, '/add'),
                  icon: Icon(Icons.add),
                  label: Text('Add Expense'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4B006E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/reports'),
                  icon: Icon(Icons.bar_chart),
                  label: Text('Reports'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 