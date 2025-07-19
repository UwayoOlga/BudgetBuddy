import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/budget_model.dart';
import '../models/savings_goal_model.dart';
import '../models/category_model.dart';

class HiveService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(IncomeAdapter().typeId)) {
      Hive.registerAdapter(IncomeAdapter());
    }
    if (!Hive.isAdapterRegistered(BudgetAdapter().typeId)) {
      Hive.registerAdapter(BudgetAdapter());
    }
    if (!Hive.isAdapterRegistered(SavingsGoalAdapter().typeId)) {
      Hive.registerAdapter(SavingsGoalAdapter());
    }
    if (!Hive.isAdapterRegistered(CategoryAdapter().typeId)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    await Future.wait([
      _openBox<User>('users'),
      _openBox<Expense>('expenses'),
      _openBox<Income>('incomes'),
      _openBox<Budget>('budgets'),
      _openBox<SavingsGoal>('savings'),
      _openBox('session'),
      _openBox<Category>('categories'),
    ]);
    _initialized = true;
  }

  static Future<void> _openBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<T>(name);
    }
  }

  static Box<User> getUserBox() => Hive.box<User>('users');
  static Box<Expense> getExpenseBox() => Hive.box<Expense>('expenses');
  static Box<Income> getIncomeBox() => Hive.box<Income>('incomes');
  static Box<Budget> getBudgetBox() => Hive.box<Budget>('budgets');
  static Box<SavingsGoal> getSavingsBox() => Hive.box<SavingsGoal>('savings');
  static Box<Category> getCategoryBox() => Hive.box<Category>('categories');
  static Box getSessionBox() => Hive.box('session');

  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }
} 