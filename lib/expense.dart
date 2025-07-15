import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

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
  final descController = TextEditingController();
  final categories = ['Food', 'Transport', 'Books', 'Fun', 'Other'];
  final paymentMethods = ['Cash', 'Debit Card', 'Mobile Money'];

  void addExpense() async {
    if (amount > 0) {
      await DatabaseHelper.instance.addExpense({
        'userId': widget.userId,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'description': description,
        'paymentMethod': paymentMethod
      });
      Navigator.pop(context);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: categories.map((cat) {
                  IconData icon;
                  switch (cat) {
                    case 'Food': icon = Icons.fastfood; break;
                    case 'Transport': icon = Icons.directions_bus; break;
                    case 'Books': icon = Icons.book; break;
                    case 'Fun': icon = Icons.celebration; break;
                    default: icon = Icons.category;
                  }
                  return GestureDetector(
                    onTap: () => setState(() => category = cat),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: category == cat ? Color(0xFF6C2EB7) : Color(0xFF2D0146),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(icon, color: Colors.white),
                          SizedBox(height: 4),
                          Text(cat, style: TextStyle(fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
              Text('Description', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              TextField(
                controller: descController,
                onChanged: (v) => description = v,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'e.g. Coffee with friends'),
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
                  child: Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 