import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/scheduler.dart';
import '../services/hive_service.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/budget_model.dart';
import '../models/savings_goal_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  final int userId;
  const ReportsScreen({super.key, required this.userId});
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
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      var expensesBox = HiveService.getExpenseBox();
      var incomesBox = HiveService.getIncomeBox();
      var budgetsBox = HiveService.getBudgetBox();
      var savingsBox = HiveService.getSavingsBox();
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
        start = now.subtract(const Duration(days: 7));
      } else {
        start = DateTime(2000);
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
      setState(() { errorMessage = 'Failed to load report data.'; });
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load report data: $e')),
          );
        }
      });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('BudgetBuddy Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('Summary:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Total Income: ${incomes.fold(0.0, (a, b) => a + (b['amount'] ?? 0)).toStringAsFixed(2)}'),
          pw.Text('Total Expenses: ${expenses.fold(0.0, (a, b) => a + (b['amount'] ?? 0)).toStringAsFixed(2)}'),
          pw.Text('Profit/Loss: ${(incomes.fold(0.0, (a, b) => a + (b['amount'] ?? 0)) - expenses.fold(0.0, (a, b) => a + (b['amount'] ?? 0))).toStringAsFixed(2)}'),
          pw.SizedBox(height: 16),
          pw.Text('Expenses:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Date', 'Category', 'Amount', 'Description', 'Payment'],
            data: expenses.map((e) => [e['date'], e['category'], e['amount'].toStringAsFixed(2), e['description'], e['paymentMethod']]).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Incomes:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Date', 'Source', 'Amount', 'Notes'],
            data: incomes.map((i) => [i['date'], i['source'], i['amount'].toStringAsFixed(2), i['notes']]).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Budgets:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Category', 'Amount', 'Month', 'Period'],
            data: budgets.map((b) => [b['category'], b['amount'].toStringAsFixed(2), b['month'], b['period']]).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Savings Goals:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Name', 'Target', 'Saved', 'Target Date'],
            data: savings.map((s) => [s['name'], s['targetAmount'].toStringAsFixed(2), s['savedAmount'].toStringAsFixed(2), s['targetDate'].toString()]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  List<PieChartSectionData> getPieSections() {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final colors = [const Color(0xFF6C2EB7), const Color(0xFFB388FF), const Color(0xFF9575CD), const Color(0xFFCE93D8), const Color(0xFFF5F5F5)];
    int i = 0;
    return categoryTotals.entries.map((e) {
      final percent = total == 0 ? 0 : (e.value / total * 100).round();
      return PieChartSectionData(
        color: colors[i++ % colors.length],
        value: e.value,
        title: percent > 0 ? '$percent%' : '',
        radius: 48,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = incomes.fold(0.0, (a, b) => a + (b['amount'] ?? 0));
    final totalExpenses = expenses.fold(0.0, (a, b) => a + (b['amount'] ?? 0));
    final profit = totalIncome - totalExpenses;
    bool boxesOpen = HiveService.getExpenseBox().isOpen && HiveService.getIncomeBox().isOpen && HiveService.getBudgetBox().isOpen && HiveService.getSavingsBox().isOpen;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              var sessionBox = HiveService.getSessionBox();
              await sessionBox.delete('userId');
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: !boxesOpen
          ? const Center(child: Text('Error: Data not available. Please restart the app.', style: TextStyle(color: Colors.redAccent)))
          : (loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C2EB7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export to PDF'),
                          onPressed: exportToPDF,
                        ),
                      ],
                    ),
                    // PROFIT/LOSS SUMMARY
                    Card(
                      color: profit > 0 ? Colors.green[900] : (profit < 0 ? Colors.red[900] : const Color(0xFF2D0146)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              profit > 0 ? Icons.trending_up : (profit < 0 ? Icons.trending_down : Icons.horizontal_rule),
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                profit > 0
                                  ? 'Profit: +${profit.toStringAsFixed(2)}'
                                  : (profit < 0
                                    ? 'Loss: ${profit.toStringAsFixed(2)}'
                                    : 'Break-even'),
                                style: const TextStyle(
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
                        const Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
                        DropdownButton<String>(
                          value: period,
                          dropdownColor: const Color(0xFF2D0146),
                          style: const TextStyle(color: Colors.white),
                          items: ['This Month', 'Last 7 Days'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) => setState(() { period = v!; loadData(); }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Filter:', style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: filterCategory,
                            dropdownColor: const Color(0xFF2D0146),
                            style: const TextStyle(color: Colors.white),
                            items: allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() { filterCategory = v!; loadData(); }),
                          ),
                          const SizedBox(width: 16),
                          const Text('Payment:', style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: filterPaymentMethod,
                            dropdownColor: const Color(0xFF2D0146),
                            style: const TextStyle(color: Colors.white),
                            items: allPaymentMethods.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() { filterPaymentMethod = v!; loadData(); }),
                          ),
                          const SizedBox(width: 16),
                          const Text('Sort by:', style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: sortBy,
                            dropdownColor: const Color(0xFF2D0146),
                            style: const TextStyle(color: Colors.white),
                            items: const [DropdownMenuItem(value: 'date', child: Text('Date')), DropdownMenuItem(value: 'amount', child: Text('Amount'))],
                            onChanged: (v) => setState(() { sortBy = v!; loadData(); }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Income: +${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        Text('Total Expenses: -${totalExpenses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Budgets', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    ...budgets.map((b) => Card(
                      color: const Color(0xFF2D0146),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('${b['category']} (${b['period']})', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Amount: ${b['amount'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                      ),
                    )),
                    const SizedBox(height: 16),
                    const Text('Savings Goals', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    ...savings.map((s) => Card(
                      color: const Color(0xFF2D0146),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(s['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Saved: ${s['savedAmount'].toStringAsFixed(2)} / ${s['targetAmount'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                        trailing: Text('Target: ${DateFormat('yyyy-MM-dd').format(s['targetDate'])}', style: const TextStyle(color: Colors.white54)),
                      ),
                    )),
                    const SizedBox(height: 24),
                    const Text('Spending by Category', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D0146),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: categoryTotals.isEmpty
                          ? const Text('No data', style: TextStyle(color: Colors.white54))
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
                    const SizedBox(height: 24),
                    const Text('All Activities', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    ...(() {
                      final allActivities = [
                        ...incomes.map((i) => {'type': 'income', ...i, 'date': i['date'] ?? DateTime.now().toString()}),
                        ...expenses.map((e) => {'type': 'expense', ...e, 'date': e['date'] ?? DateTime.now().toString()}),
                        ...savings.map((s) => {
                          'type': 'savings',
                          ...s,
                          'date': s['targetDate'] != null ? s['targetDate'].toString() : DateTime.now().toString(),
                        })
                      ];
                      allActivities.sort((a, b) {
                        try {
                          return DateTime.parse(b['date'] ?? DateTime.now().toString()).compareTo(DateTime.parse(a['date'] ?? DateTime.now().toString()));
                        } catch (_) {
                          return 0;
                        }
                      });
                      return allActivities.map((t) => Card(
                        color: t['type'] == 'income'
                          ? const Color(0xFF1A4D2E)
                          : t['type'] == 'expense'
                            ? const Color(0xFF4B006E)
                            : const Color(0xFF2D0146),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 4),
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
                              ? (t['source'] ?? 'Income')
                              : t['type'] == 'expense'
                                ? (t['category'] ?? 'Expense')
                                : (t['name'] ?? 'Savings'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            t['type'] == 'income'
                              ? (t['notes'] ?? '')
                              : t['type'] == 'expense'
                                ? (t['description'] ?? '')
                                : 'Saved: ${(t['savedAmount'] ?? 0).toStringAsFixed(2)} / ${(t['targetAmount'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (t['type'] == 'income')
                                Text('+' + (t['amount'] ?? 0).toStringAsFixed(2), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              if (t['type'] == 'expense')
                                Text('-' + (t['amount'] ?? 0).toStringAsFixed(2), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              if (t['type'] == 'savings')
                                const Icon(Icons.savings, color: Colors.amberAccent),
                            ],
                          ),
                        ),
                      ));
                    })(),
                    if (incomes.isEmpty && expenses.isEmpty && savings.isEmpty)
                      const Text('No activities', style: TextStyle(color: Colors.white54)),
                  ],
                )
            ),
    );
  }
} 