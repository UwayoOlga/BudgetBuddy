import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('budgetbuddy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        amount REAL,
        category TEXT,
        date TEXT,
        description TEXT,
        paymentMethod TEXT,
        isRecurring INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        amount REAL,
        source TEXT,
        date TEXT,
        notes TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        month TEXT,
        amount REAL,
        category TEXT,
        period TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE savings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        name TEXT,
        targetAmount REAL,
        savedAmount REAL,
        targetDate TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
  }

  Future<int> registerUser(String username, String password) async {
    final db = await instance.database;
    var hash = sha256.convert(utf8.encode(password)).toString();
    return await db.insert('users', {'username': username, 'password': hash});
  }

  Future<int?> loginUser(String username, String password) async {
    final db = await instance.database;
    var hash = sha256.convert(utf8.encode(password)).toString();
    var res = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, hash]);
    if (res.isNotEmpty) return res.first['id'] as int;
    return null;
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await instance.database;
    var res = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> addExpense(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('expenses', data);
  }

  Future<List<Map<String, dynamic>>> getExpenses(int userId) async {
    final db = await instance.database;
    return await db.query('expenses', where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
  }

  Future<int> addBudget(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('budgets', data);
  }

  Future<Map<String, dynamic>?> getBudget(int userId, String month) async {
    final db = await instance.database;
    var res = await db.query('budgets', where: 'userId = ? AND month = ?', whereArgs: [userId, month]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> addSavings(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('savings', data);
  }

  Future<List<Map<String, dynamic>>> getSavings(int userId) async {
    final db = await instance.database;
    return await db.query('savings', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> addIncome(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('incomes', data);
  }

  Future<List<Map<String, dynamic>>> getIncomes(int userId) async {
    final db = await instance.database;
    return await db.query('incomes', where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
  }

  Future<int> deleteIncome(int id) async {
    final db = await instance.database;
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecurringExpenses(int userId) async {
    final db = await instance.database;
    return await db.query('expenses', where: 'userId = ? AND isRecurring = 1', whereArgs: [userId]);
  }

  Future<void> autoAddRecurringExpenses(int userId, DateTime now) async {
    final db = await instance.database;
    final recurs = await getRecurringExpenses(userId);
    for (var e in recurs) {
      DateTime lastDate = DateTime.parse(e['date']);
      if (lastDate.month != now.month || lastDate.year != now.year) {
        await db.insert('expenses', {
          'userId': userId,
          'amount': e['amount'],
          'category': e['category'],
          'date': DateTime(now.year, now.month, lastDate.day).toIso8601String(),
          'description': e['description'],
          'paymentMethod': e['paymentMethod'],
          'isRecurring': 1,
        });
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 