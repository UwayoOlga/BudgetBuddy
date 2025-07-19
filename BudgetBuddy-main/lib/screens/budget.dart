import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget_model.dart';
import '../services/hive_service.dart';

class BudgetScreen extends StatefulWidget {
  final int userId;
  const BudgetScreen({super.key, required this.userId});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<String> categories = ['Food', 'Transport', 'Books', 'Fun', 'Other'];
  String period = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0146),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D0146),
        elevation: 0,
        title: const Text('Budgets', style: TextStyle(color: Colors.white)),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Budget>('budgets').listenable(),
        builder: (context, Box<Budget> box, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Budgets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
                  DropdownButton<String>(
                    value: period,
                    dropdownColor: const Color(0xFF2D0146),
                    style: const TextStyle(color: Colors.white),
                    items: ['Monthly', 'Weekly'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => period = v!),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...categories.map((cat) {
                final budgets = box.values.where((b) => b.userId == widget.userId && b.category == cat && b.period == period).toList();
                final b = budgets.isNotEmpty ? budgets.first : null;
                final amount = b?.amount ?? 0.0;
                return Card(
                  color: const Color(0xFF4B006E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(cat, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Period: $period', style: const TextStyle(color: Colors.white70)),
                    trailing: Text(amount.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => EditBudgetDialog(userId: widget.userId, category: cat, period: period, budget: b),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class EditBudgetDialog extends StatefulWidget {
  final int userId;
  final String category;
  final String period;
  final Budget? budget;
  const EditBudgetDialog({super.key, required this.userId, required this.category, required this.period, this.budget});
  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  final amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    amountController.text = widget.budget?.amount.toString() ?? '';
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void saveBudget() async {
    final amt = double.tryParse(amountController.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid amount', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }
    final box = Hive.box<Budget>('budgets');
    if (widget.budget == null) {
      await box.add(Budget(
        userId: widget.userId,
        month: DateTime.now().toString().substring(0, 7),
        amount: amt,
        category: widget.category,
        period: widget.period,
      ));
    } else {
      final b = widget.budget!;
      b.amount = amt;
      await b.save();
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Budget saved', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D0146),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Budget for ${widget.category}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Amount',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF4B006E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C2EB7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: saveBudget,
                child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 