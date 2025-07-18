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

class _IncomeScreenState extends State<IncomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool showAddDialog = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void showIncomeDialog({Income? income}) {
    double amount = income?.amount ?? 0;
    String source = income?.source ?? '';
    DateTime date = income?.date ?? DateTime.now();
    String notes = income?.notes ?? '';
    final amountController = TextEditingController(text: amount == 0 ? '' : amount.toString());
    final sourceController = TextEditingController(text: source);
    final notesController = TextEditingController(text: notes);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF2D0146),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(income == null ? 'Add Income' : 'Update Income', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
                    SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: 'Amount'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: sourceController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: 'Source'),
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
                    SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: 'Notes'),
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
                          onPressed: () async {
                            double? amt = double.tryParse(amountController.text);
                            if (amt == null || sourceController.text.trim().isEmpty) return;
                            var incomesBox = Hive.box<Income>('incomes');
                            if (income == null) {
                              await incomesBox.add(Income(
                                userId: widget.userId,
                                amount: amt,
                                source: sourceController.text.trim(),
                                date: date,
                                notes: notesController.text.trim(),
                              ));
                            } else {
                              income.amount = amt;
                              income.source = sourceController.text.trim();
                              income.date = date;
                              income.notes = notesController.text.trim();
                              await income.save();
                            }
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: Text(income == null ? 'Add' : 'Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var incomesBox = Hive.box<Income>('incomes');
    var incomes = incomesBox.values.where((i) => i.userId == widget.userId).toList();
    incomes.sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
        title: Text('My Income'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF6C2EB7)),
            onPressed: () => showIncomeDialog(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: incomes.isEmpty
            ? Center(child: Text('No income records', style: TextStyle(color: Colors.white54, fontSize: 18)))
            : AnimatedList(
                key: ValueKey(incomes.length),
                initialItemCount: incomes.length,
                itemBuilder: (context, i, animation) {
                  var inc = incomes[i];
                  return SizeTransition(
                    sizeFactor: animation,
                    child: Card(
                      color: Color(0xFF2D0146),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(inc.source, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('${inc.notes} - ${DateFormat('yyyy-MM-dd').format(inc.date)}', style: TextStyle(color: Colors.white70)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.white70),
                              onPressed: () => showIncomeDialog(income: inc),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                await inc.delete();
                                setState(() {});
                              },
                            ),
                            Text('+${inc.amount.toStringAsFixed(2)}', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
} 