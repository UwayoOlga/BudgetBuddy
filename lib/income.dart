import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'income_model.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  final int userId;
  IncomeScreen({required this.userId});
  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  void showUpdateIncomeDialog(Income income) {
    double amount = income.amount;
    String source = income.source;
    DateTime date = income.date;
    String notes = income.notes;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D0146),
        title: Text('Update Income', style: TextStyle(color: Color(0xFF6C2EB7))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = double.tryParse(v) ?? 0,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Amount'),
                controller: TextEditingController(text: income.amount.toString()),
              ),
              SizedBox(height: 8),
              TextField(
                onChanged: (v) => source = v,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Source'),
                controller: TextEditingController(text: income.source),
              ),
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
              SizedBox(height: 8),
              TextField(
                onChanged: (v) => notes = v,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Notes'),
                controller: TextEditingController(text: income.notes),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
            onPressed: () async {
              income.amount = amount;
              income.source = source;
              income.date = date;
              income.notes = notes;
              await income.save();
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var incomesBox = Hive.box<Income>('incomes');
    var incomes = incomesBox.values.where((i) => i.userId == widget.userId).toList();
    return Scaffold(
      appBar: AppBar(title: Text('My Income')),
      body: ListView.builder(
        itemCount: incomes.length,
        itemBuilder: (context, i) {
          var inc = incomes[i];
          return ListTile(
            title: Text(inc.source, style: TextStyle(color: Colors.white)),
            subtitle: Text('${inc.notes} - ${DateFormat('yyyy-MM-dd').format(inc.date)}', style: TextStyle(color: Colors.white70)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white70),
                  onPressed: () async {
                    showUpdateIncomeDialog(inc);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    await inc.delete();
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 