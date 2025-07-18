import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'user.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  String error = '';

  void register() async {
    String username = usernameController.text.trim();
    String password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() { error = 'All fields required'; });
      return;
    }
    var usersBox = Hive.box<User>('users');
    bool exists = usersBox.values.any((u) => u.username == username);
    if (exists) {
      setState(() { error = 'Username already exists'; });
      return;
    }
    var hash = sha256.convert(utf8.encode(password)).toString();
    int userId = await usersBox.add(User(username: username, passwordHash: hash));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registration Successful'),
        content: Text('Your account has been created. Please log in.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
                SizedBox(height: 32),
                TextField(
                  controller: usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Username'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (error.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(error, style: TextStyle(color: Colors.redAccent)),
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C2EB7),
                    padding: EdgeInsets.symmetric(horizontal: 64, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: register,
                  child: Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text('Already have an account? Login', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  String error = '';

  void login() async {
    String username = usernameController.text.trim();
    String password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() { error = 'All fields required'; });
      return;
    }
    var usersBox = Hive.box<User>('users');
    var hash = sha256.convert(utf8.encode(password)).toString();
    final userEntry = usersBox.toMap().entries.firstWhere(
      (entry) => entry.value.username == username && entry.value.passwordHash == hash,
      orElse: () => MapEntry(-1, User(username: '', passwordHash: '')),
    );
    if (userEntry.key != -1) {
      final userId = userEntry.key;
      Navigator.pushReplacementNamed(context, '/home', arguments: userId);
    } else {
      setState(() { error = 'Invalid username or password'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
                SizedBox(height: 32),
                TextField(
                  controller: usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Username'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (error.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(error, style: TextStyle(color: Colors.redAccent)),
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C2EB7),
                    padding: EdgeInsets.symmetric(horizontal: 64, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: login,
                  child: Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                  child: Text('Don\'t have an account? Register', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 