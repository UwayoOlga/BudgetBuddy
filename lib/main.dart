import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth.dart';

void main() {
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
        if (settings.name == '/home') {
          final userId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => MainAppScreen(userId: userId));
        }
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => SplashScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => LoginScreen());
        }
        return null;
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
    return Scaffold(
      body: Center(
        child: Text('BudgetBuddy', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6C2EB7))),
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
    final screens = [
      DashboardScreen(userId: widget.userId),
      AddExpenseScreen(userId: widget.userId),
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
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final int userId;
  DashboardScreen({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Dashboard', style: TextStyle(fontSize: 24)));
  }
}

class AddExpenseScreen extends StatelessWidget {
  final int userId;
  AddExpenseScreen({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Add Expense', style: TextStyle(fontSize: 24)));
  }
}

class ReportsScreen extends StatelessWidget {
  final int userId;
  ReportsScreen({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Reports', style: TextStyle(fontSize: 24)));
  }
}

class SavingsScreen extends StatelessWidget {
  final int userId;
  SavingsScreen({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Savings', style: TextStyle(fontSize: 24)));
  }
}

class SettingsScreen extends StatelessWidget {
  final int userId;
  SettingsScreen({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Settings', style: TextStyle(fontSize: 24)));
  }
}
