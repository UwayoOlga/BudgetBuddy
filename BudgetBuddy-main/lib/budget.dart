import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'budget_model.dart';

class BudgetScreen extends StatefulWidget {
  final int userId;
  BudgetScreen({required this.userId});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<String> categories = ['Food', 'Transport', 'Books', 'Fun', 'Other'];
  String period = 'Monthly';
  Map<String, double> categoryBudgets = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    setState(() { loading = true; });
    var budgetsBox = Hive.box<Budget>('budgets');
    for (var cat in categories) {
      var b = budgetsBox.values.firstWhere(
        (b) => b.userId == widget.userId && b.category == cat && b.period == period,
        orElse: () => Budget.defaultBudget(),
      ) as Budget?;
      categoryBudgets[cat] = b != null ? (b.amount) : 0;
    }
    setState(() { loading = false; });
  }

  void showEditBudgetDialog(String cat) {
    double amount = categoryBudgets[cat] ?? 0;
    var budgetsBox = Hive.box<Budget>('budgets');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D0146),
        title: Text('Set Budget for $cat', style: TextStyle(color: Color(0xFF6C2EB7))),
        content: TextField(
          keyboardType: TextInputType.number,
          onChanged: (v) => amount = double.tryParse(v) ?? 0,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
            onPressed: () async {
              try {
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid amount.')),
                  );
                  return;
                }
                var existing = budgetsBox.values.firstWhere(
                  (b) => b.userId == widget.userId && b.category == cat && b.period == period,
                  orElse: () => Budget.defaultBudget(),
                ) as Budget?;
                if (existing != null) {
                  existing.amount = amount;
                  await existing.save();
                } else {
                  await budgetsBox.add(Budget(
                    userId: widget.userId,
                    month: '',
                    amount: amount,
                    category: cat,
                    period: period,
                  ));
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Budget saved!')),
                );
                Navigator.pop(context);
                loadBudgets();
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Error'),
                    content: Text('Failed to save budget: \n$e'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Center(child: CircularProgressIndicator()) : ListView(
      padding: EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budgets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
            DropdownButton<String>(
              value: period,
              dropdownColor: Color(0xFF2D0146),
              style: TextStyle(color: Colors.white),
              items: ['Monthly', 'Weekly'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() { period = v!; loadBudgets(); }),
            ),
          ],
        ),
        SizedBox(height: 24),
        ...categories.map((cat) {
          var budgetsBox = Hive.box<Budget>('budgets');
          var b = budgetsBox.values.firstWhere(
            (b) => b.userId == widget.userId && b.category == cat && b.period == period,
            orElse: () => Budget.defaultBudget(),
          ) as Budget?;
          double budget = categoryBudgets[cat] ?? 0;
          return Card(
            color: Color(0xFF2D0146),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(cat, style: TextStyle(color: Colors.white)),
              subtitle: Text('${budget.toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Color(0xFF6C2EB7)),
                    onPressed: () => showEditBudgetDialog(cat),
                  ),
                  if (b != null)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        await b.delete();
                        loadBudgets();
                      },
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
} 