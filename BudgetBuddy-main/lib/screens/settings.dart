import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/hive_service.dart';
import '../models/user.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/budget_model.dart';
import '../models/savings_goal_model.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  const SettingsScreen({super.key, required this.userId});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  String currency = 'USD';
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController schoolNameController;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    var usersBox = HiveService.getUserBox();
    var user = usersBox.get(widget.userId) as User?;
    usernameController = TextEditingController(text: user?.username ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    schoolNameController = TextEditingController(text: user?.schoolName ?? '');
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    schoolNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void showProfileUpdateDialog() {
    var usersBox = HiveService.getUserBox();
    var user = usersBox.get(widget.userId) as User?;
    if (user != null) {
      usernameController.text = user.username;
      emailController.text = user.email;
      schoolNameController.text = user.schoolName;
    }
    showDialog(
      context: context,
      builder: (context) {
        _animController.forward(from: 0);
        return ScaleTransition(
          scale: _scaleAnim,
          child: AlertDialog(
            backgroundColor: const Color(0xFF2D0146),
            title: const Text('Update Profile', style: TextStyle(color: Color(0xFF6C2EB7))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: schoolNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'School Name'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2EB7)),
                onPressed: () async {
                  try {
                    var usersBox = HiveService.getUserBox();
                    var latestUser = usersBox.get(widget.userId) as User?;
                    if (latestUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not found.')),
                      );
                      return;
                    }
                    if (usernameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Username cannot be empty.')),
                      );
                      return;
                    }
                    latestUser.username = usernameController.text;
                    latestUser.email = emailController.text;
                    latestUser.schoolName = schoolNameController.text;
                    await latestUser.save();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated!')),
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text('Failed to update profile: \n$e'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                  }
                },
                child: const Text('Update', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              var sessionBox = HiveService.getSessionBox();
              await sessionBox.delete('userId');
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2EB7)),
            onPressed: showProfileUpdateDialog,
            child: const Text('Update Profile', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 24),
          const Text('Currency', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: currency,
            dropdownColor: const Color(0xFF2D0146),
            style: const TextStyle(color: Colors.white),
            items: ['USD', 'EUR', 'GBP', 'KES', 'NGN', 'INR', 'RWF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => currency = v!),
          ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                var sessionBox = HiveService.getSessionBox();
                await sessionBox.delete('userId');
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }
} 