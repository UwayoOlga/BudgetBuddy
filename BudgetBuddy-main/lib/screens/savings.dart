import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/savings_goal_model.dart';
import 'package:intl/intl.dart';
import '../services/hive_service.dart';
import '../services/notifications.dart';

class SavingsScreen extends StatelessWidget {
  final int userId;
  const SavingsScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    // Check for reminders
    final savingsBox = HiveService.getSavingsBox();
    final now = DateTime.now();
    final goals = savingsBox.values.where((g) => g.userId == userId).toList();
    String? reminderMsg;
    for (final g in goals) {
      final daysLeft = g.targetDate.difference(now).inDays;
      if (daysLeft < 0 && g.savedAmount < g.targetAmount) {
        reminderMsg = 'Goal "${g.name}" is overdue!';
        break;
      } else if (daysLeft <= 3 && g.savedAmount < g.targetAmount) {
        reminderMsg = 'Goal "${g.name}" is due in $daysLeft day(s)!';
        break;
      }
    }
    return Scaffold(
      backgroundColor: const Color(0xFF2D0146),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D0146),
        elevation: 0,
        title: const Text('Savings Goals', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddSavingsGoalDialog(userId: userId),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          if (reminderMsg != null)
            NotificationsBanner(reminder: reminderMsg),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: savingsBox.listenable(),
              builder: (context, box, _) {
                final goals = box.values.where((g) => g.userId == userId).toList();
                if (goals.isEmpty) {
                  return Center(child: Text('No savings goals yet.', style: TextStyle(color: Colors.white54)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final g = goals[i];
                    final percent = g.targetAmount == 0 ? 0.0 : (g.savedAmount / g.targetAmount).clamp(0.0, 1.0);
                    return Dismissible(
                      key: ValueKey(g.key),
                      background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 24), child: Icon(Icons.delete, color: Colors.white))),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (_) async {
                        await g.delete();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goal deleted', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                      },
                      child: ListTile(
                        tileColor: const Color(0xFF4B006E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        title: Text(g.name, style: TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Target: ${g.targetAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
                            Text('Saved: ${g.savedAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
                            Text('Target Date: ${DateFormat('yyyy-MM-dd').format(g.targetDate)}', style: TextStyle(color: Colors.white70)),
                            LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.white24,
                              color: percent >= 1.0 ? Colors.greenAccent : const Color(0xFF6C2EB7),
                              minHeight: 8,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AddSavingsGoalDialog(userId: userId, goal: g),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddSavingsGoalDialog extends StatefulWidget {
  final int userId;
  final SavingsGoal? goal;
  const AddSavingsGoalDialog({super.key, required this.userId, this.goal});
  @override
  State<AddSavingsGoalDialog> createState() => _AddSavingsGoalDialogState();
}

class _AddSavingsGoalDialogState extends State<AddSavingsGoalDialog> {
  String name = '';
  double target = 0;
  double saved = 0;
  DateTime? targetDate;
  final nameController = TextEditingController();
  final targetController = TextEditingController();
  final savedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      name = widget.goal!.name;
      target = widget.goal!.targetAmount;
      saved = widget.goal!.savedAmount;
      targetDate = widget.goal!.targetDate;
      nameController.text = name;
      targetController.text = target.toString();
      savedController.text = saved.toString();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    targetController.dispose();
    savedController.dispose();
    super.dispose();
  }

  void saveGoal() async {
    final t = double.tryParse(targetController.text);
    final s = double.tryParse(savedController.text);
    if (nameController.text.trim().isEmpty || t == null || t <= 0 || s == null || s < 0 || targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields with valid values.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }
    final box = Hive.box<SavingsGoal>('savings');
    if (widget.goal == null) {
      await box.add(SavingsGoal(
        userId: widget.userId,
        name: nameController.text.trim(),
        targetAmount: t,
        savedAmount: s,
        targetDate: targetDate!,
      ));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goal added', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    } else {
      final g = widget.goal!;
      g.name = nameController.text.trim();
      g.targetAmount = t;
      g.savedAmount = s;
      g.targetDate = targetDate!;
      await g.save();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goal updated', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D0146),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.goal == null ? 'Add Savings Goal' : 'Edit Savings Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Goal Name',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF4B006E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Target Amount',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF4B006E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: savedController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Saved Amount',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF4B006E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Target Date', style: TextStyle(color: Colors.white70)),
                trailing: Text(targetDate == null ? 'Pick target date' : DateFormat('yyyy-MM-dd').format(targetDate!), style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate ?? DateTime.now(),
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
                  if (picked != null) setState(() => targetDate = picked);
                },
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
                  onPressed: saveGoal,
                  child: Text(widget.goal == null ? 'Add' : 'Update', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 