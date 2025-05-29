import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ReceiptNumberHelper {
  static final ReceiptNumberHelper instance =
      ReceiptNumberHelper._privateConstructor();

  static Database? _database;

  ReceiptNumberHelper._privateConstructor();

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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receiptnumber (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER
      )
    ''');
  }

  Future<void> insertReceiptNumber() async {
    Database db = await database;
    await db.insert(
      'receiptnumber',
      {'number': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getReceiptNumber() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query('receiptnumber');
    if (result.isNotEmpty) {
      return result.first['number'] as int;
    } else {
      // If no receipt number exists, insert the initial receipt number (1)
      await insertReceiptNumber();
      return 1;
    }
  }

  Future<void> updateReceiptNumber() async {
    Database db = await database;
    int currentNumber = await getReceiptNumber();
    int updatedNumber = currentNumber + 1;
    await db.update(
      'receiptnumber',
      {'number': updatedNumber},
    );
  }

  Future<void> resetReceiptNumber(int newNumber) async {
    Database db = await database;
    await db.update(
      'receiptnumber',
      {'number': newNumber},
    );
  }

  Future<List<String>> getAllTables() async {
    Database db = await database;
    List<Map<String, dynamic>> tables = await db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    List<String> tableNames =
        tables.map((table) => table['name'] as String).toList();
    return tableNames;
  }
}
