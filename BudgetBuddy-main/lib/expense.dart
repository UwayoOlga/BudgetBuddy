import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'expense_model.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final int userId;
  AddExpenseScreen({required this.userId});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  double amount = 0;
  String category = 'Food';
  DateTime date = DateTime.now();
  String description = '';
  String paymentMethod = 'Cash';
  bool isRecurring = false;
  final descController = TextEditingController();
  final categories = ['Food', 'Transport', 'Books', 'Fun', 'Other'];
  final paymentMethods = ['Cash', 'Debit Card', 'Mobile Money'];

  void addExpense() async {
    try {
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid amount.')),
        );
        return;
      }
      var expensesBox = Hive.box<Expense>('expenses');
      await expensesBox.add(Expense(
        userId: widget.userId,
        amount: amount,
        category: category,
        date: date,
        description: description,
        paymentMethod: paymentMethod,
        isRecurring: isRecurring,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to add expense: \n$e'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    }
  }

  Widget buildKeypad() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: 12,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2),
        itemBuilder: (context, i) {
          String label;
          if (i < 9) label = '${i + 1}';
          else if (i == 9) label = '.';
          else if (i == 10) label = '0';
          else label = '<';
          return GestureDetector(
            onTap: () {
              setState(() {
                if (label == '<') {
                  var s = amount.toStringAsFixed(2);
                  if (s.length > 1) s = s.substring(0, s.length - 1);
                  amount = double.tryParse(s) ?? 0;
                } else if (label == '.') {
                  if (!amount.toString().contains('.')) amount = double.parse(amount.toString() + '.');
                } else {
                  var s = amount == 0 ? label : amount.toStringAsFixed(2) + label;
                  amount = double.tryParse(s) ?? amount;
                }
              });
            },
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF2D0146),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(label, style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Expense')),
      floatingActionButton: FloatingActionButton(
        onPressed: addExpense,
        child: Icon(Icons.check),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Color(0xFF2D0146),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    amount == 0 ? '0' : amount.toStringAsFixed(2),
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              buildKeypad(),
              SizedBox(height: 16),
              Text('Category', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    IconData icon;
                    String imageUrl = '';
                    switch (cat) {
                      case 'Food':
                        icon = Icons.fastfood;
                        imageUrl = 'https://img.icons8.com/color/48/000000/meal.png';
                        break;
                      case 'Transport':
                        icon = Icons.directions_bus;
                        imageUrl = 'https://img.icons8.com/color/48/000000/bus.png';
                        break;
                      case 'Books':
                        icon = Icons.book;
                        imageUrl = 'https://img.icons8.com/color/48/000000/book.png';
                        break;
                      case 'Fun':
                        icon = Icons.celebration;
                        imageUrl = 'https://img.icons8.com/color/48/000000/confetti.png';
                        break;
                      default:
                        icon = Icons.category;
                        imageUrl = 'https://img.icons8.com/color/48/000000/money.png';
                    }
                    return GestureDetector(
                      onTap: () => setState(() => category = cat),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: category == cat ? Color(0xFF6C2EB7) : Color(0xFF2D0146),
                          borderRadius: BorderRadius.circular(12),
                          border: category == cat ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        child: Column(
                          children: [
                            Image.network(
                              imageUrl,
                              width: 32,
                              height: 32,
                              errorBuilder: (context, error, stackTrace) => Icon(icon, size: 32, color: Colors.white54),
                            ),
                            SizedBox(height: 4),
                            Text(cat, style: TextStyle(fontSize: 12, color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16),
              Text('Date', style: TextStyle(fontSize: 18)),
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
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2D0146),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(date), style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              SizedBox(height: 16),
              Text('Notes (optional)', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              TextField(
                controller: descController,
                onChanged: (v) => description = v,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'e.g. Coffee with friends'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: isRecurring,
                    onChanged: (v) => setState(() => isRecurring = v ?? false),
                    activeColor: Color(0xFF6C2EB7),
                  ),
                  Text('Recurring expense', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 16),
              Text('Payment Method', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => paymentMethod = v!),
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C2EB7),
                    padding: EdgeInsets.symmetric(horizontal: 64, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: addExpense,
                  child: Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseListScreen extends StatefulWidget {
  final int userId;
  ExpenseListScreen({required this.userId});
  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseScreenListDialog extends StatelessWidget {
  final Expense? expense;
  final Function(Expense? expense, double amount, String category, DateTime date, String description, String paymentMethod, bool isRecurring) onSave;
  final List<String> categories;
  final List<String> paymentMethods;
  final int userId;
  _ExpenseScreenListDialog({this.expense, required this.onSave, required this.categories, required this.paymentMethods, required this.userId});
  @override
  Widget build(BuildContext context) {
    double amount = expense?.amount ?? 0;
    String category = expense?.category ?? categories.first;
    DateTime date = expense?.date ?? DateTime.now();
    String description = expense?.description ?? '';
    String paymentMethod = expense?.paymentMethod ?? paymentMethods.first;
    bool isRecurring = expense?.isRecurring ?? false;
    final amountController = TextEditingController(text: amount == 0 ? '' : amount.toString());
    final descController = TextEditingController(text: description);
    return Dialog(
      backgroundColor: Color(0xFF2D0146),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(expense == null ? 'Add Expense' : 'Edit Expense', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Amount'),
              ),
              SizedBox(height: 12),
              DropdownButton<String>(
                value: category,
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v!,
              ),
              SizedBox(height: 12),
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
                  if (picked != null) date = picked;
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
              SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Description'),
              ),
              SizedBox(height: 12),
              DropdownButton<String>(
                value: paymentMethod,
                dropdownColor: Color(0xFF2D0146),
                style: TextStyle(color: Colors.white),
                items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => paymentMethod = v!,
              ),
              SizedBox(height: 12),
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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
                    onPressed: () {
                      double? amt = double.tryParse(amountController.text);
                      if (amt == null || category.isEmpty) return;
                      onSave(expense, amt, category, date, descController.text, paymentMethod, isRecurring);
                      Navigator.pop(context);
                    },
                    child: Text(expense == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<String> categories = ['Food', 'Transport', 'Books', 'Fun', 'Other'];
  List<String> paymentMethods = ['Cash', 'Debit Card', 'Mobile Money'];
  @override
  Widget build(BuildContext context) {
    var expensesBox = Hive.box<Expense>('expenses');
    var expenses = expensesBox.values.where((e) => e.userId == widget.userId).toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
        title: Text('My Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF6C2EB7)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _ExpenseScreenListDialog(
                  categories: categories,
                  paymentMethods: paymentMethods,
                  userId: widget.userId,
                  onSave: (expense, amount, category, date, description, paymentMethod, isRecurring) async {
                    var expensesBox = Hive.box<Expense>('expenses');
                    await expensesBox.add(Expense(
                      userId: widget.userId,
                      amount: amount,
                      category: category,
                      date: date,
                      description: description,
                      paymentMethod: paymentMethod,
                      isRecurring: isRecurring,
                    ));
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: expenses.isEmpty
          ? Center(child: Text('No expenses recorded', style: TextStyle(color: Colors.white54, fontSize: 18)))
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, i) {
                var e = expenses[i];
                return Card(
                  color: Color(0xFF2D0146),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(e.category, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${e.description} - ${DateFormat('yyyy-MM-dd').format(e.date)}', style: TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.white70),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => _ExpenseScreenListDialog(
                                expense: e,
                                categories: categories,
                                paymentMethods: paymentMethods,
                                userId: widget.userId,
                                onSave: (expense, amount, category, date, description, paymentMethod, isRecurring) async {
                                  e.amount = amount;
                                  e.category = category;
                                  e.date = date;
                                  e.description = description;
                                  e.paymentMethod = paymentMethod;
                                  e.isRecurring = isRecurring;
                                  await e.save();
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await e.delete();
                            setState(() {});
                          },
                        ),
                        Text('-${e.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 