import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelperPayments {
  static final DatabaseHelperPayments instance =
      DatabaseHelperPayments._privateConstructor();

  static Database? _database;

  DatabaseHelperPayments._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;

    await _initDatabase();
    return _database!;
  }

  Future<void> _initDatabase() async {
    sqfliteFfiInit(); // Initialize sqflite_common_ffi
    databaseFactory = databaseFactoryFfi; // Set the database factory

    String path = await _getDatabasePath();
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'emetdb.db');
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
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
      )
    ''');
  }

  Future<int> insertPayment(Map<String, dynamic> payment) async {
    Database db = await instance.database;
    // Ensure the table exists before inserting data
    await _createDb(db, 1);
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getUnpaidPaymentsWithClientDetails(
      String selectedMonth) async {
    final Database db = await instance.database;

    final List<Map<String, dynamic>> unpaidPayments = await db.rawQuery('''
    SELECT payments.*, clients.name AS clientName, clients.phone AS clientPhone
    FROM payments
    LEFT JOIN clients ON payments.clientId = clients.id
    WHERE payments.month = ?
      AND payments.status IS NULL
  ''', [selectedMonth]);

    return unpaidPayments;
  }
}
