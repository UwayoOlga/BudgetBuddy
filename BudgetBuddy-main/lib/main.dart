import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth.dart';
import 'screens/dashboard.dart';
import 'screens/reports.dart';
import 'screens/savings.dart';
import 'screens/settings.dart';
import 'screens/income.dart';
import 'screens/budget.dart';
import 'screens/calendar.dart';
import 'screens/expense.dart';
import 'services/hive_service.dart';
import 'models/user.dart';
import 'models/expense_model.dart';
import 'models/income_model.dart';
import 'models/budget_model.dart';
import 'models/savings_goal_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A0023),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C2EB7),
          secondary: Color(0xFFF5F5F5),
          surface: Color(0xFF1A0023),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4B006E),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6C2EB7),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D0146),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => SplashScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => LoginScreen());
          case '/home': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => MainAppScreen(userId: userId));
            }
            return _errorRoute();
          }
          case '/add': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => ExpenseListScreen(userId: userId));
            }
            return _errorRoute();
          }
          case '/reports': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => ReportsScreen(userId: userId));
            }
            return _errorRoute();
          }
          case '/calendar': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => CalendarScreen(userId: userId));
            }
            return _errorRoute();
          }
          case '/income': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => IncomeListScreen(userId: userId));
            }
            return _errorRoute();
          }
          case '/budget': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => BudgetScreen(userId: userId));
            }
            return _errorRoute();
          }
          case '/savings': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => SavingsScreen(userId: userId));
            }
            return _errorRoute();
          }
          case '/settings': {
            final userId = settings.arguments;
            if (userId is int) {
              return MaterialPageRoute(builder: (_) => SettingsScreen(userId: userId));
            }
            return _errorRoute();
          }
          default:
            return _errorRoute();
        }
      },
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () async {
            await HiveService.closeAll();
            return true;
          },
          child: child ?? Container(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> _checkSession(BuildContext context) async {
    try {
      var sessionBox = Hive.box('session');
      final userId = sessionBox.get('userId');
      if (userId is int && Hive.box<User>('users').containsKey(userId)) {
        Navigator.pushReplacementNamed(context, '/home', arguments: userId);
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () => _checkSession(context));
    return const Scaffold(
      body: Center(
        child: Text('BudgetBuddy', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
    try {
      var usersBox = Hive.box<User>('users');
      var hash = sha256.convert(utf8.encode(password)).toString();
      final userEntry = usersBox.toMap().entries.firstWhere(
        (entry) => entry.value.username == username && entry.value.passwordHash == hash,
        orElse: () => MapEntry(-1, User(username: '', passwordHash: '')),
      );
      if (userEntry.key != -1) {
        final userId = userEntry.key;
        // Save session
        var sessionBox = Hive.box('session');
        await sessionBox.put('userId', userId);
        Navigator.pushReplacementNamed(context, '/home', arguments: userId);
      } else {
        setState(() { error = 'Invalid username or password'; });
      }
    } catch (e) {
      setState(() { error = 'Login failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
                const SizedBox(height: 32),
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Username'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(error, style: const TextStyle(color: Colors.redAccent)),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C2EB7),
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: login,
                  child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                  child: const Text('Don\'t have an account? Register', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainAppScreen extends StatefulWidget {
  final int userId;
  const MainAppScreen({super.key, required this.userId});
  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _index = 0;
  void logout() async {
    var sessionBox = Hive.box('session');
    await sessionBox.delete('userId');
    Navigator.pushReplacementNamed(context, '/login');
  }
  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(userId: widget.userId),
      ExpenseListScreen(userId: widget.userId),
      IncomeListScreen(userId: widget.userId),
      BudgetScreen(userId: widget.userId),
      CalendarScreen(userId: widget.userId),
      ReportsScreen(userId: widget.userId),
      SavingsScreen(userId: widget.userId),
      SettingsScreen(userId: widget.userId),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2D0146),
        selectedItemColor: const Color(0xFF6C2EB7),
        unselectedItemColor: Colors.white,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Income'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('BudgetBuddy', style: TextStyle(fontSize: 24, color: Color(0xFF6C2EB7)))),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }
}

Route<dynamic> _errorRoute() {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(child: Text('Page not found or invalid arguments.')),
    ),
  );
}
