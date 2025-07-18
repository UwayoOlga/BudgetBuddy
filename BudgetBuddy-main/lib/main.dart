import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth.dart';
import 'dashboard.dart';
import 'reports.dart';
import 'savings.dart';
import 'settings.dart';
import 'income.dart';
import 'budget.dart';
import 'calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'user.dart';
import 'expense_model.dart';
import 'income_model.dart';
import 'budget_model.dart';
import 'savings_goal_model.dart';
import 'expense.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(SavingsGoalAdapter());
  await Hive.openBox<User>('users');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Income>('incomes');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<SavingsGoal>('savings');
  // DEV ONLY: Clear old/corrupt data on first run. Remove after first successful run.
  // await Hive.box<Budget>('budgets').clear();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1A0023),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6C2EB7),
          secondary: Color(0xFFF5F5F5),
          background: Color(0xFF1A0023),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF4B006E),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6C2EB7),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2D0146),
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
              return MaterialPageRoute(builder: (_) => AddExpenseScreen(userId: userId));
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
              return MaterialPageRoute(builder: (_) => IncomeScreen(userId: userId));
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
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('SplashScreen loaded');
    Future.delayed(Duration(seconds: 2), () {
      print('Navigating to login');
      Navigator.pushReplacementNamed(context, '/login');
    });
    return Scaffold(
      body: Center(
        child: Text('BudgetBuddy', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
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

class MainAppScreen extends StatefulWidget {
  final int userId;
  MainAppScreen({required this.userId});
  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    print('MainAppScreen loaded for userId:  [32m [1m');
    print(widget.userId);
    print('\u001b[0m');
    final screens = [
      DashboardScreen(userId: widget.userId),
      AddExpenseScreen(userId: widget.userId),
      IncomeScreen(userId: widget.userId),
      BudgetScreen(userId: widget.userId),
      CalendarScreen(userId: widget.userId),
      ReportsScreen(userId: widget.userId),
      SavingsScreen(userId: widget.userId),
      SettingsScreen(userId: widget.userId),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF2D0146),
        selectedItemColor: Color(0xFF6C2EB7),
        unselectedItemColor: Colors.white,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: [
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
    );
  }
}

Route<dynamic> _errorRoute() {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text('Error')),
      body: Center(child: Text('Page not found or invalid arguments.')),
    ),
  );
}
