// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/payment_transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "transactions.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            sender TEXT,
            receiver TEXT,
            amount REAL,
            note TEXT,
            timestamp TEXT,
            status TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertTransaction(PaymentTransaction tx) async {
    final db = await database;
    await db.insert(
      "transactions",
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PaymentTransaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query("transactions", orderBy: "timestamp DESC");
    return maps.map((m) => PaymentTransaction.fromMap(m)).toList();
  }

  Future<void> updateTransaction(PaymentTransaction tx) async {
    final db = await database;
    await db.update("transactions", tx.toMap(),
        where: "id = ?", whereArgs: [tx.id]);
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete("transactions");
  }
}
