import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'user.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'expense_model.dart';
import 'income_model.dart';
import 'budget_model.dart';
import 'savings_goal_model.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  SettingsScreen({required this.userId});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String currency = 'USD';
  void showProfileUpdateDialog() {
    var usersBox = Hive.box('users');
    var user = usersBox.get(widget.userId);
    String username = user?.username ?? '';
    String email = user?.email ?? '';
    String schoolName = user?.schoolName ?? '';
    String address = user?.address ?? '';
    String password = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D0146),
        title: Text('Update Profile', style: TextStyle(color: Color(0xFF6C2EB7))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => username = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Username'),
              controller: TextEditingController(text: user?.username ?? ''),
            ),
            SizedBox(height: 8),
            TextField(
              onChanged: (v) => email = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Email'),
              controller: TextEditingController(text: user?.email ?? ''),
            ),
            SizedBox(height: 8),
            TextField(
              onChanged: (v) => schoolName = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'School Name'),
              controller: TextEditingController(text: user?.schoolName ?? ''),
            ),
            SizedBox(height: 8),
            TextField(
              onChanged: (v) => address = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Address'),
              controller: TextEditingController(text: user?.address ?? ''),
            ),
            SizedBox(height: 8),
            TextField(
              onChanged: (v) => password = v,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'New Password (leave blank to keep current)'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
            onPressed: () async {
              try {
                if (username.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Username cannot be empty.')),
                  );
                  return;
                }
                user?.username = username;
                user?.email = email;
                user?.schoolName = schoolName;
                user?.address = address;
                if (password.isNotEmpty) {
                  user?.passwordHash = sha256.convert(utf8.encode(password)).toString();
                }
                await user?.save();
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile updated!')),
                );
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Error'),
                    content: Text('Failed to update profile: \n$e'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              }
            },
            child: Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> backupData() async {
    var usersBox = Hive.box('users');
    var expensesBox = Hive.box('expenses');
    var incomesBox = Hive.box('incomes');
    var budgetsBox = Hive.box('budgets');
    var savingsBox = Hive.box('savings');
    Map<String, dynamic> data = {
      'users': usersBox.values.map((u) => u.toMap()).toList(),
      'expenses': expensesBox.values.map((e) => e.toMap()).toList(),
      'incomes': incomesBox.values.map((i) => i.toMap()).toList(),
      'budgets': budgetsBox.values.map((b) => b.toMap()).toList(),
      'savings': savingsBox.values.map((s) => s.toMap()).toList(),
    };
    String jsonStr = jsonEncode(data);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/budgetbuddy_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved to ${file.path}')));
  }

  Future<void> restoreData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      String jsonStr = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(jsonStr);
      var usersBox = Hive.box('users');
      var expensesBox = Hive.box('expenses');
      var incomesBox = Hive.box('incomes');
      var budgetsBox = Hive.box('budgets');
      var savingsBox = Hive.box('savings');
      await usersBox.clear();
      await expensesBox.clear();
      await incomesBox.clear();
      await budgetsBox.clear();
      await savingsBox.clear();
      for (var u in data['users']) { usersBox.add(User.fromMap(u)); }
      for (var e in data['expenses']) { expensesBox.add(Expense.fromMap(e)); }
      for (var i in data['incomes']) { incomesBox.add(Income.fromMap(i)); }
      for (var b in data['budgets']) { budgetsBox.add(Budget.fromMap(b)); }
      for (var s in data['savings']) { savingsBox.add(SavingsGoal.fromMap(s)); }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data restored successfully')));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
        SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
          onPressed: showProfileUpdateDialog,
          child: Text('Update Profile', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(height: 24),
        Text('Currency', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        DropdownButton<String>(
          value: currency,
          dropdownColor: Color(0xFF2D0146),
          style: TextStyle(color: Colors.white),
          items: ['USD', 'EUR', 'GBP', 'KES', 'NGN', 'INR', 'RWF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => currency = v!),
        ),
        SizedBox(height: 24),
        Text('Data Management', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
          onPressed: backupData,
          child: Text('Backup Data', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4B006E)),
          onPressed: restoreData,
          child: Text('Restore Data', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(height: 24),
        Text('About', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        Text('BudgetBuddy helps students track expenses, manage budgets, and save smartly.', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 8),
        Text('Contact: uwayoolga@gmail.com', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
} 