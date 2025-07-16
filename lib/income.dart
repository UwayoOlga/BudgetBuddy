import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  final int userId;
  IncomeScreen({required this.userId});
  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  List<Map<String, dynamic>> incomes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; });
    incomes = await DatabaseHelper.instance.getIncomes(widget.userId);
    setState(() { loading = false; });
  }

  void showAddIncomeDialog() {
    double amount = 0;
    String source = '';
    DateTime date = DateTime.now();
    String notes = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D0146),
        title: Text('Add Income', style: TextStyle(color: Color(0xFF6C2EB7))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (v) => amount = double.tryParse(v) ?? 0,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Amount'),
            ),
            SizedBox(height: 8),
            TextField(
              onChanged: (v) => source = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Source (e.g. Allowance, Job, Scholarship)'),
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
                if (picked != null) setState(() => date = picked);
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
              decoration: InputDecoration(hintText: 'Notes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
            onPressed: () async {
              if (amount > 0 && source.isNotEmpty) {
                await DatabaseHelper.instance.addIncome({
                  'userId': widget.userId,
                  'amount': amount,
                  'source': source,
                  'date': date.toIso8601String(),
                  'notes': notes,
                });
                Navigator.pop(context);
                loadData();
              }
            },
            child: Text('Add'),
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
            Text('Income', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
              onPressed: showAddIncomeDialog,
              icon: Icon(Icons.add),
              label: Text('Add Income'),
            ),
          ],
        ),
        SizedBox(height: 24),
        ...incomes.map((i) => Card(
          color: Color(0xFF2D0146),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(i['source'] ?? '', style: TextStyle(color: Colors.white)),
            subtitle: Text('${i['notes'] ?? ''} - ${DateFormat('yyyy-MM-dd').format(DateTime.parse(i['date']))}', style: TextStyle(color: Colors.white70)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('+${i['amount'].toStringAsFixed(2)}', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteIncome(i['id']);
                    loadData();
                  },
                ),
              ],
            ),
          ),
        )),
        if (incomes.isEmpty)
          Text('No income records', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
} 