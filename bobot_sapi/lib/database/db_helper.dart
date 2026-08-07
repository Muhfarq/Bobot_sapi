import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bobot_sapi.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 3, // Version dinaikkan untuk mengakomodasi panjang_badan & goal_hari
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sapi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_sapi TEXT NOT NULL,
        tanggal_masuk TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pengukuran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sapi_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        lingkar_dada REAL NOT NULL,
        panjang_badan REAL NOT NULL,
        bobot_sekarang REAL NOT NULL,
        estimasi_pakan REAL NOT NULL,
        goal_hari INTEGER NOT NULL,
        target_bobot REAL NOT NULL,
        sisa_bobot REAL NOT NULL,
        adg REAL NOT NULL,
        estimasi_bulan REAL NOT NULL,
        tanggal_panen TEXT NOT NULL,
        FOREIGN KEY (sapi_id) REFERENCES sapi(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE pengukuran ADD COLUMN goal_hari INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE pengukuran ADD COLUMN panjang_badan REAL NOT NULL DEFAULT 0.0',
      );
    }
  }

  Future<int> insertSapi(SapiModel sapi) async {
    final db = await database;
    return await db.insert('sapi', sapi.toMap());
  }

  Future<int> insertPengukuran(PengukuranModel pengukuran) async {
    final db = await database;
    return await db.insert('pengukuran', pengukuran.toMap());
  }

  Future<List<SapiModel>> getAllSapi() async {
    final db = await database;
    final result = await db.query('sapi', orderBy: 'id DESC');
    return result.map((e) => SapiModel.fromMap(e)).toList();
  }

  Future<List<SapiModel>> searchSapi(String keyword) async {
    final db = await database;
    final result = await db.query(
      'sapi',
      where: 'nama_sapi LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );
    return result.map((e) => SapiModel.fromMap(e)).toList();
  }

  Future<List<PengukuranModel>> getPengukuranBySapi(int sapiId) async {
    final db = await database;
    final result = await db.query(
      'pengukuran',
      where: 'sapi_id = ?',
      whereArgs: [sapiId],
      orderBy: 'tanggal DESC',
    );
    return result.map((e) => PengukuranModel.fromMap(e)).toList();
  }

  Future<List<PengukuranModel>> getAllPengukuran() async {
    final db = await database;
    final result = await db.query('pengukuran', orderBy: 'id DESC');
    return result.map((e) => PengukuranModel.fromMap(e)).toList();
  }

  Future<int> deleteSapi(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete('pengukuran', where: 'sapi_id = ?', whereArgs: [id]);
      return await txn.delete('sapi', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> deletePengukuran(int id) async {
    final db = await database;
    return await db.delete('pengukuran', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}