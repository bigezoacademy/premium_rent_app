import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PropertiesManager {
  static final PropertiesManager instance =
      PropertiesManager._privateConstructor();

  static Database? _database;

  PropertiesManager._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await _getDatabasePath();
    print('Database path: $path');
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
      CREATE TABLE IF NOT EXISTS properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        location TEXT
      )
    ''');
  }

  Future<int> insertProperty(Map<String, dynamic> property) async {
    Database db = await instance.database;
    return await db.insert('properties', property);
  }

  Future<List<Map<String, dynamic>>> getProperties() async {
    Database db = await instance.database;
    return await db.query('properties');
  }

  Future<int> updateProperty(int id, Map<String, dynamic> property) async {
    Database db = await instance.database;
    return await db.update(
      'properties',
      property,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProperty(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'properties',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
