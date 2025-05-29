import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await _getDatabasePath();
    print('Database path: $path'); // Print the database path
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'emetdb.db');

    // Check if the database file already exists
    if (!await File(dbPath).exists()) {
      // Copy the bundled database file to the application documents directory
      ByteData data = await rootBundle.load('assets/emetdb.db');
      List<int> bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes);
    }

    return dbPath;
  }

  Future<void> _createDb(Database db, int version) async {
    // Your database creation logic
    await db.execute('''
    CREATE TABLE clients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      phone TEXT,
      apartment TEXT,
      room TEXT
    )
  ''');

    await _createPaymentsTable(db);
    await _createDbReceipt(db);
  }

  Future<void> _createPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER,
        paymentDate TEXT,
        amount REAL,
        amountInWords TEXT,
        reasonOfPayment TEXT,
        payerPhone TEXT,
        balance REAL,
        status TEXT,
        dueDate TEXT,
        month TEXT,
        year TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id)
      );
    ''');
  }

  Future<int> insertClient(Map<String, dynamic> client) async {
    Database db = await instance.database;
    // If the client is new, set the fields to null
    if (client['id'] == null) {
      client['name'] = null;
      client['phone'] = null;
      client['apartment'] = null;
      client['room'] = null;
    }
    return await db.insert('clients', client);
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    Database db = await instance.database;

    return await db.query('clients');
  }

  Future<Map<String, dynamic>> getClientByName(String name) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'clients',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : {};
  }

  Future<int> updateClient(int id, Map<String, dynamic> updatedClient) async {
    Database db = await instance.database;
    return await db.update(
      'clients',
      updatedClient,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteClient(int clientId) async {
    Database db = await instance.database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [clientId]);
  }

  Future<int> insertPayment(Map<String, dynamic> payment) async {
    Database db = await instance.database;
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    Database db = await instance.database;
    return await db.query('payments');
  }

  Future<int> insertOrUpdatePaymentForMonth(
      Map<String, dynamic> payment) async {
    Database db = await instance.database;

    int clientId = payment['clientId'];
    DateTime currentDate = DateTime.now(); // Capture the current date

    // Check if a payment for the specified month already exists
    List<Map<String, dynamic>> existingPayments = await db.query(
      'payments',
      where: 'clientId = ? ',
      whereArgs: [clientId],
    );

    if (existingPayments.isNotEmpty) {
      // Update existing payment details for the month
      return await db.update(
        'payments',
        payment,
        where: 'clientId = ? ',
        whereArgs: [clientId],
      );
    } else {
      // Insert new payment details for the month
      return await db.insert('payments', {
        ...payment,
        'paymentDate': currentDate.toIso8601String(), // Use the current date
      });
    }
  }

  Future<List<Map<String, dynamic>>> getUnpaidPayments(
      String selectedMonth) async {
    Database db = await instance.database;

    // Replace 'YourPaymentLogicTable' with the actual name of your payments table
    return await db.query(
      'payments',
      columns: ['clientId', 'amount', 'balance'],
      where: 'status != ?',
      whereArgs: ['paid'],
    );
  }

  // Method to fetch payments for a specific month
  Future<List<Map<String, dynamic>>> getPaymentsForMonth(
      int clientId, String year) async {
    Database db = await instance.database;

    return await db.query(
      'payments',
      where: 'clientId = ?  AND year = ?',
      whereArgs: [clientId, year],
    );
  }

  // Method to create the payments table independently
  Future<void> createPaymentsTable() async {
    Database db = await instance.database;
    await _createPaymentsTable(db);
  }

  Future<void> _createDbReceipt(Database db) async {
    await db.execute('''
      CREATE TABLE receiptnumber (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER
      );
    ''');
  }

  Future<void> createDbReceipt() async {
    Database db = await instance.database;
    await _createDbReceipt(db);
  }
}
