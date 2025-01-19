// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:galaxyscholars/db_utils.dart';

// class SQLiteService {
//   static final SQLiteService _instance = SQLiteService._internal();
//   Database? _database;

//   factory SQLiteService() {
//     return _instance;
//   }

//   SQLiteService._internal();

//   /// Initialize the SQLite database
//   Future<void> initialize() async {
//     final dbPath = await getCustomDatabasePath();
//     final path = join(dbPath, 'app_data.db');

//     _database = await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE IF NOT EXISTS boards (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             name TEXT UNIQUE
//           );
//         ''');
//         await db.execute('''
//           CREATE TABLE IF NOT EXISTS standards (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             name INTEGER UNIQUE
//           );
//         ''');
//         await db.execute('''
//           CREATE TABLE IF NOT EXISTS subjects (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             name TEXT UNIQUE
//           );
//         ''');
//         await db.execute('''
//           CREATE TABLE IF NOT EXISTS topics (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             subject_id INTEGER REFERENCES subjects(id),
//             name TEXT UNIQUE
//           );
//         ''');
//         await db.execute('''
//           CREATE TABLE IF NOT EXISTS content (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             board_id INTEGER REFERENCES boards(id),
//             standard_id INTEGER REFERENCES standards(id),
//             subject_id INTEGER REFERENCES subjects(id),
//             topic_id INTEGER REFERENCES topics(id),
//             official_definition TEXT,
//             layman_explanation TEXT,
//             inventor TEXT,
//             innovations TEXT,
//             puzzle TEXT,
//             diagram TEXT,
//             idea TEXT,
//             last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
//           );
//         ''');
//       },
//     );
//   }

//   /// Insert data into a table
//   Future<void> insert(String table, Map<String, dynamic> data) async {
//     await _database!.insert(
//       table,
//       data,
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }

//   /// Query data from a table
//   Future<List<Map<String, dynamic>>> query(String sql,
//       [List<Object?>? args]) async {
//     return await _database!.rawQuery(sql, args);
//   }

//   /// Execute raw SQL
//   Future<void> execute(String sql) async {
//     await _database!.execute(sql);
//   }

//   /// Close the database
//   Future<void> close() async {
//     await _database!.close();
//   }
// }
