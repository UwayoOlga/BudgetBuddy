import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  SettingsScreen({required this.userId});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String currency = 'USD';
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
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