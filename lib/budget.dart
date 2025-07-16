import 'package:flutter/material.dart';
import 'database_helper.dart';

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
  double overallBudget = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    setState(() { loading = true; });
    var now = DateTime.now();
    String month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    for (var cat in categories) {
      var b = await DatabaseHelper.instance.getBudget(widget.userId, month, cat, period);
      categoryBudgets[cat] = b != null ? (b['amount'] ?? 0) : 0;
    }
    setState(() { loading = false; });
  }

  void showEditBudgetDialog(String cat) {
    double amount = categoryBudgets[cat] ?? 0;
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
              var now = DateTime.now();
              String month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
              await DatabaseHelper.instance.addBudget({
                'userId': widget.userId,
                'month': month,
                'amount': amount,
                'category': cat,
                'period': period,
              });
              Navigator.pop(context);
              loadBudgets();
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
          double spent = 0; // You can fetch actual spent from expenses if needed
          double budget = categoryBudgets[cat] ?? 0;
          double percent = budget == 0 ? 0 : (spent / budget).clamp(0, 1);
          Color barColor = percent > 0.9 ? Colors.redAccent : percent > 0.7 ? Colors.orangeAccent : Color(0xFF6C2EB7);
          return Card(
            color: Color(0xFF2D0146),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(cat, style: TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Color(0xFF4B006E),
                    color: barColor,
                  ),
                  SizedBox(height: 4),
                  Text('${spent.toStringAsFixed(2)} spent / ${budget.toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF6C2EB7)),
                onPressed: () => showEditBudgetDialog(cat),
              ),
            ),
          );
        }),
      ],
    );
  }
} 