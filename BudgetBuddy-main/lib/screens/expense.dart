import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'package:intl/intl.dart';
import '../services/hive_service.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import 'income.dart' show CategoryManagerDialog;
import 'package:hive/hive.dart';
import '../services/notifications.dart';

class ExpenseListScreen extends StatelessWidget {
  final int userId;
  const ExpenseListScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0146),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D0146),
        elevation: 0,
        title: const Text('My Expenses', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddExpenseDialog(userId: userId),
            ),
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Expense>('expenses').listenable(),
        builder: (context, Box<Expense> box, _) {
          final sessionBox = HiveService.getSessionBox();
          final currency = sessionBox.get('currency', defaultValue: 'RWF');
          final expenses = box.values.where((e) => e.userId == userId).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final now = DateTime.now();
          final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
          final budgetsBox = HiveService.getBudgetBox();
          final budgetData = budgetsBox.values.firstWhere(
            (b) => b.userId == userId && b.month == month,
            orElse: () => Budget.defaultBudget(),
          );
          final budget = budgetData.amount;
          double spent = 0;
          for (var e in expenses) {
            spent += e.amount;
          }
          String? budgetWarning;
          if (budget > 0 && spent / budget >= 0.8) {
            budgetWarning = 'Warning: You have spent 80% or more of your budget!';
          }
          if (expenses.isEmpty) {
            return Center(child: Text('No expenses yet.', style: TextStyle(color: Colors.white54)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: expenses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = expenses[i];
              return Dismissible(
                key: ValueKey(e.key),
                background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 24), child: Icon(Icons.delete, color: Colors.white))),
                direction: DismissDirection.startToEnd,
                onDismissed: (_) async {
                  await e.delete();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense deleted', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                },
                child: ListTile(
                  tileColor: const Color(0xFF4B006E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text(e.category, style: TextStyle(color: Colors.white)),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(e.date), style: TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(NumberFormat.currency(symbol: ' ' + currency, decimalDigits: 2).format(e.amount), style: TextStyle(color: Colors.white)),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          await e.delete();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense deleted', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                        },
                      ),
                    ],
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => AddExpenseDialog(userId: userId, expense: e),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final int userId;
  final Expense? expense;
  const AddExpenseDialog({super.key, required this.userId, this.expense});
  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> with SingleTickerProviderStateMixin {
  double amount = 0;
  String category = 'Food';
  DateTime date = DateTime.now();
  String description = '';
  String paymentMethod = 'Cash';
  bool isRecurring = false;
  final descController = TextEditingController();
  final amountController = TextEditingController();
  late final List<String> categories;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool showSuccess = false;
  final List<String> paymentMethods = ['Cash', 'Debit Card', 'Mobile Money'];

  List<String> getUserCategories() {
    final categoryBox = HiveService.getCategoryBox();
    final userCategories = categoryBox.values.where((c) => c.userId == widget.userId && c.type == 'expense').map((c) => c.name).toList();
    if (userCategories.isEmpty) {
      return ['Food', 'Transport', 'Books', 'Fun', 'Other'];
    }
    return userCategories;
  }

  @override
  void initState() {
    super.initState();
    categories = getUserCategories();
    if (widget.expense != null) {
      amount = widget.expense!.amount;
      category = widget.expense!.category;
      date = widget.expense!.date;
      description = widget.expense!.description;
      paymentMethod = widget.expense!.paymentMethod;
      isRecurring = widget.expense!.isRecurring;
      descController.text = description;
      amountController.text = amount.toString();
    }
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    descController.dispose();
    amountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void saveExpense() async {
    final amt = double.tryParse(amountController.text);
    if (amt == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid amount and category', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }
    final expenseBox = HiveService.getExpenseBox();
    final budgetBox = HiveService.getBudgetBox();
    // Determine period (monthly for now)
    final now = DateTime.now();
    final period = 'Monthly';
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    // Sum expenses for this user/category/period/month
    final expenses = expenseBox.values.where((e) => e.userId == widget.userId && e.category == category && e.date.year == now.year && e.date.month == now.month);
    double totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    // If editing, subtract the old amount
    if (widget.expense != null) {
      totalSpent -= widget.expense!.amount;
    }
    final Budget budget = budgetBox.values.firstWhere(
      (b) => b.userId == widget.userId && b.category == category && b.period == period && b.month == monthStr,
      orElse: () => Budget.defaultBudget(),
    );
    double budgetAmount = budget.amount;
    if (budgetAmount > 0 && (totalSpent + amt) > budgetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Warning: This will exceed your $category budget for $period!', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
      ));
    }
    if (widget.expense == null) {
      await expenseBox.add(Expense(
        userId: widget.userId,
        amount: amt,
        category: category,
        date: date,
        description: descController.text,
        paymentMethod: paymentMethod,
        isRecurring: isRecurring,
      ));
      setState(() { showSuccess = true; });
      await Future.delayed(const Duration(milliseconds: 700));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense added', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    } else {
      final e = widget.expense!;
      e.amount = amt;
      e.category = category;
      e.date = date;
      e.description = descController.text;
      e.paymentMethod = paymentMethod;
      e.isRecurring = isRecurring;
      await e.save();
      setState(() { showSuccess = true; });
      await Future.delayed(const Duration(milliseconds: 700));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Expense updated', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: const Color(0xFF2D0146),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: showSuccess
                  ? Column(
                      key: const ValueKey('success'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 64),
                        const SizedBox(height: 16),
                        Text(widget.expense == null ? 'Expense Added!' : 'Expense Updated!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    )
                  : Column(
                      key: const ValueKey('form'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.expense == null ? 'Add Expense' : 'Edit Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: category,
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => category = v!),
                          dropdownColor: const Color(0xFF4B006E),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Category',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF4B006E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.category, color: Colors.white),
                              label: Text('Manage Categories', style: TextStyle(color: Colors.white)),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => CategoryManagerDialog(userId: widget.userId, type: 'expense'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Date', style: TextStyle(color: Colors.white70)),
                          trailing: Text(DateFormat('yyyy-MM-dd').format(date), style: TextStyle(color: Colors.white)),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: const Color(0xFF6C2EB7),
                                    onPrimary: Colors.white,
                                    surface: const Color(0xFF2D0146),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) setState(() => date = picked);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Description',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF4B006E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: paymentMethod,
                          items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => paymentMethod = v!),
                          dropdownColor: const Color(0xFF4B006E),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Payment Method',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF4B006E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: isRecurring,
                          onChanged: (v) => setState(() => isRecurring = v),
                          title: const Text('Recurring', style: TextStyle(color: Colors.white)),
                          activeColor: const Color(0xFF6C2EB7),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C2EB7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: saveExpense,
                            child: Text(widget.expense == null ? 'Add Expense' : 'Update Expense', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
} 