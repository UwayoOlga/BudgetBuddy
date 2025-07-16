import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:budget_buddy/models/user.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  SettingsScreen({required this.userId});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String currency = 'USD';
  void showProfileUpdateDialog() {
    var usersBox = Hive.box<User>('users');
    var user = usersBox.get(widget.userId);
    String username = user?.username ?? '';
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
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C2EB7)),
            onPressed: () async {
              if (username.isNotEmpty) {
                user?.username = username;
                if (password.isNotEmpty) {
                  user?.passwordHash = sha256.convert(utf8.encode(password)).toString();
                }
                await user?.save();
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
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
          child: Text('Update Profile'),
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
          onPressed: () {},
          child: Text('Backup Data'),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4B006E)),
          onPressed: () {},
          child: Text('Restore Data'),
        ),
        SizedBox(height: 24),
        Text('About', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        Text('BudgetBuddy helps students track expenses, manage budgets, and save smartly.', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 8),
        Text('Contact: support@budgetbuddy.app', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
} 