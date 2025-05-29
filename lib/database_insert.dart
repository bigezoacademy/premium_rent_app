import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelperInsert {
  static final DatabaseHelperInsert instance =
      DatabaseHelperInsert._privateConstructor();

  static Database? _database;

  DatabaseHelperInsert._privateConstructor();

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
    final dbPath = join(directory.path, 'premium_rent_app.db');

    // Check if the database file already exists
    if (!await File(dbPath).exists()) {
      // Copy the bundled database file to the application documents directory
      ByteData data = await rootBundle.load('assets/premium_rent_app.db');
      List<int> bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes);
    }

    return dbPath;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        apartment TEXT,
        room TEXT
      )
    ''');
  }

  Future<int> insertClient(Map<String, dynamic> client) async {
    Database db = await instance.database;
    // Ensure the table exists before inserting data
    await _createDb(db, 1);
    return await db.insert('clients', client);
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    Database db = await instance.database;
    // Ensure the table exists before querying data
    await _createDb(db, 1);
    return await db.query('clients');
  }
}
