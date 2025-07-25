import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income_model.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../services/hive_service.dart';
import '../services/notifications.dart';

class IncomeListScreen extends StatelessWidget {
  final int userId;
  const IncomeListScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0146),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D0146),
        elevation: 0,
        title: const Text('My Income', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddIncomeDialog(userId: userId),
            ),
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Income>('incomes').listenable(),
        builder: (context, Box<Income> box, _) {
          final sessionBox = HiveService.getSessionBox();
          final currency = sessionBox.get('currency', defaultValue: 'RWF');
          final remindersEnabled = sessionBox.get('remindersEnabled', defaultValue: true);
          final salaryDay = sessionBox.get('salaryDay', defaultValue: 25);
          final incomes = box.values.where((i) => i.userId == userId).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final now = DateTime.now();
          String? incomeReminder;
          final thisMonthIncome = incomes.any((i) => i.date.year == now.year && i.date.month == now.month);
          if (remindersEnabled && now.day == salaryDay && !thisMonthIncome) {
            incomeReminder = 'Reminder: Today is your expected salary day. Don\'t forget to log your income!';
          }
          if (incomes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_money, color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text('No income records yet.', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }
          return Column(
            children: [
              if (incomeReminder != null)
                NotificationsBanner(reminder: incomeReminder),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: incomes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final inc = incomes[i];
                    return Dismissible(
                      key: ValueKey(inc.key),
                      background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 24), child: Icon(Icons.delete, color: Colors.white))),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (_) async {
                        try {
                          await inc.delete();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Income deleted', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                        } catch (err) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete income. Please try again.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                        }
                      },
                      child: ListTile(
                        tileColor: const Color(0xFF4B006E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        title: Text(inc.source, style: TextStyle(color: Colors.white)),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(inc.date), style: TextStyle(color: Colors.white70)),
                        trailing: Text(NumberFormat.currency(symbol: ' ' + currency, decimalDigits: 2).format(inc.amount), style: TextStyle(color: Colors.white)),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => AddIncomeDialog(userId: userId, income: inc),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AddIncomeDialog extends StatefulWidget {
  final int userId;
  final Income? income;
  const AddIncomeDialog({super.key, required this.userId, this.income});
  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  double amount = 0;
  String source = '';
  DateTime date = DateTime.now();
  String notes = '';
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.income != null) {
      amount = widget.income!.amount;
      source = widget.income!.source;
      date = widget.income!.date;
      notes = widget.income!.notes;
      amountController.text = amount.toString();
      notesController.text = notes;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void saveIncome() async {
    final amt = double.tryParse(amountController.text.trim());
    if (amt == null || amt <= 0 || source.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid amount and source', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }
    final box = Hive.box<Income>('incomes');
    if (widget.income == null) {
      try {
        await box.add(Income(
          userId: widget.userId,
          amount: amt,
          source: source.trim(),
          date: date,
          notes: notesController.text.trim(),
        ));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Income added', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add income. Please try again.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      }
    } else {
      final inc = widget.income!;
      inc.amount = amt;
      inc.source = source.trim();
      inc.date = date;
      inc.notes = notesController.text.trim();
      try {
        await inc.save();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Income updated', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update income. Please try again.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      }
    }
  }

  List<String> getUserCategories() {
    final categoryBox = HiveService.getCategoryBox();
    final userCategories = categoryBox.values.where((c) => c.userId == widget.userId && c.type == 'income').map((c) => c.name).toList();
    if (userCategories.isEmpty) {
      return ['Salary', 'Gift', 'Business', 'Other'];
    }
    return userCategories;
  }

  @override
  Widget build(BuildContext context) {
    final categories = getUserCategories();
    return Dialog(
      backgroundColor: const Color(0xFF2D0146),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.income == null ? 'Add Income' : 'Edit Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: source.isNotEmpty ? source : 'Amount',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Amount',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF4B006E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categories.contains(source) ? source : null,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => source = v ?? ''),
                dropdownColor: const Color(0xFF4B006E),
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
                      builder: (context) => CategoryManagerDialog(userId: widget.userId, type: 'income'),
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
                          onSurface: Colors.white,
                        ),
                        dialogBackgroundColor: const Color(0xFF4B006E),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Notes',
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
                  onPressed: saveIncome,
                  child: Text(widget.income == null ? 'Add' : 'Update', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryManagerDialog extends StatefulWidget {
  final int userId;
  final String type; // 'expense' or 'income'
  const CategoryManagerDialog({super.key, required this.userId, required this.type});
  @override
  State<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<CategoryManagerDialog> {
  final TextEditingController controller = TextEditingController();
  String? editingCategory;

  @override
  Widget build(BuildContext context) {
    final box = HiveService.getCategoryBox();
    final categories = box.values.where((c) => c.userId == widget.userId && c.type == widget.type).toList();
    return Dialog(
      backgroundColor: const Color(0xFF2D0146),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Manage Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            ...categories.map((cat) => ListTile(
              title: Text(cat.name, style: TextStyle(color: Colors.white)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        editingCategory = cat.name;
                        controller.text = cat.name;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      try {
                        await cat.delete();
                        setState(() {});
                      } catch (err) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete category. Please try again.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                      }
                    },
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Category name',
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2EB7)),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    if (editingCategory != null) {
                      final cat = categories.firstWhere((c) => c.name == editingCategory);
                      cat.name = name;
                      try {
                        await cat.save();
                      } catch (err) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update category. Please try again.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                      }
                      setState(() { editingCategory = null; controller.clear(); });
                    } else {
                      try {
                        await box.add(Category(userId: widget.userId, name: name, type: widget.type));
                      } catch (err) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add category. Please try again.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                      }
                      setState(() { controller.clear(); });
                    }
                  },
                  child: Text(editingCategory != null ? 'Update' : 'Add', style: TextStyle(color: Colors.white)),
                ),
                if (editingCategory != null)
                  TextButton(
                    onPressed: () => setState(() { editingCategory = null; controller.clear(); }),
                    child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 