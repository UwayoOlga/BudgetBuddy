import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'savings_goal_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

class SavingsScreen extends StatefulWidget {
  final int userId;
  SavingsScreen({required this.userId});
  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  bool loading = true;
  bool showConfetti = false;
  List<SavingsGoal> goals = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; });
    var savingsBox = Hive.box<SavingsGoal>('savings');
    goals = savingsBox.values.where((g) => g.userId == widget.userId).toList();
    setState(() { loading = false; });
  }

  void showAddGoalDialog() {
    String name = '';
    double target = 0;
    DateTime? targetDate;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D0146),
        title: Text('New Savings Goal', style: TextStyle(color: Color(0xFF6C2EB7))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => name = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Goal name'),
            ),
            SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (v) => target = double.tryParse(v) ?? 0,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Target amount'),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
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
                if (picked != null) setState(() => targetDate = picked);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF4B006E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(targetDate == null ? 'Pick target date' : DateFormat('yyyy-MM-dd').format(targetDate!), style: TextStyle(color: Colors.white)),
              ),
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
              if (name.isNotEmpty && target > 0 && targetDate != null) {
                var savingsBox = Hive.box<SavingsGoal>('savings');
                await savingsBox.add(SavingsGoal(
                  userId: widget.userId,
                  name: name,
                  targetAmount: target,
                  savedAmount: 0,
                  targetDate: targetDate!,
                ));
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

  void showUpdateGoalDialog(SavingsGoal goal) {
    String name = goal.name;
    double target = goal.targetAmount;
    double saved = goal.savedAmount;
    DateTime targetDate = goal.targetDate;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D0146),
        title: Text('Update Goal', style: TextStyle(color: Color(0xFF6C2EB7))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => name = v,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Goal name'),
                controller: TextEditingController(text: goal.name),
              ),
              SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (v) => target = double.tryParse(v) ?? 0,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Target amount'),
                controller: TextEditingController(text: goal.targetAmount.toString()),
              ),
              SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (v) => saved = double.tryParse(v) ?? 0,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Saved amount'),
                controller: TextEditingController(text: goal.savedAmount.toString()),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate,
                    firstDate: DateTime.now(),
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
                  if (picked != null) targetDate = picked;
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4B006E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(targetDate), style: TextStyle(color: Colors.white)),
                ),
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
              goal.name = name;
              goal.targetAmount = target;
              goal.savedAmount = saved;
              goal.targetDate = targetDate;
              await goal.save();
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
    return Stack(
      children: [
        loading ? Center(child: CircularProgressIndicator()) : ListView(
          padding: EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Savings Goals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
                  onPressed: showAddGoalDialog,
                  icon: Icon(Icons.add),
                  label: Text('Add Goal'),
                ),
              ],
            ),
            SizedBox(height: 24),
            ...goals.map((g) {
              double percent = g.targetAmount == 0 ? 0 : (g.savedAmount / g.targetAmount).clamp(0, 1);
              bool completed = percent >= 1;
              if (completed && !showConfetti) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  setState(() { showConfetti = true; });
                  Future.delayed(Duration(seconds: 2), () => setState(() { showConfetti = false; }));
                });
              }
              return Card(
                color: Color(0xFF2D0146),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g.name, style: TextStyle(fontSize: 18, color: Colors.white)),
                          Text('${g.savedAmount.toStringAsFixed(2)} / ${g.targetAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(0xFF4B006E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            height: 16,
                            width: MediaQuery.of(context).size.width * percent * 0.7,
                            decoration: BoxDecoration(
                              color: completed ? Colors.green : Color(0xFFB388FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Target: ${DateFormat('yyyy-MM-dd').format(g.targetDate)}', style: TextStyle(color: Colors.white54)),
                      if (completed)
                        Center(
                          child: Icon(Icons.celebration, color: Colors.amber, size: 32),
                        ),
                      if (!completed)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.alarm, color: Colors.white54, size: 18),
                              SizedBox(width: 4),
                              Text('Set reminder to save', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.white70),
                            onPressed: () async {
                              showUpdateGoalDialog(g);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              await g.delete();
                              loadData();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (goals.isEmpty)
              Text('No savings goals', style: TextStyle(color: Colors.white54)),
          ],
        ),
        if (showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Text('🎉', style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
      ],
    );
  }
} 