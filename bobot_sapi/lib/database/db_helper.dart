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
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
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
        bobot_sekarang REAL NOT NULL,
        estimasi_pakan REAL NOT NULL,
        target_bobot REAL NOT NULL,
        sisa_bobot REAL NOT NULL,
        adg REAL NOT NULL,
        estimasi_bulan REAL NOT NULL,
        tanggal_panen TEXT NOT NULL,
        FOREIGN KEY (sapi_id) REFERENCES sapi(id) ON DELETE CASCADE
      )
    ''');
  }

  // ================= INSERT SAPI =================
  Future<int> insertSapi(SapiModel sapi) async {
    final db = await database;
    return await db.insert('sapi', sapi.toMap());
  }

  // ================= INSERT PENGUKURAN =================
  Future<int> insertPengukuran(PengukuranModel pengukuran) async {
    final db = await database;
    return await db.insert('pengukuran', pengukuran.toMap());
  }

  // ================= GET SEMUA SAPI =================
  Future<List<SapiModel>> getAllSapi() async {
    final db = await database;

    final result = await db.query(
      'sapi',
      orderBy: 'id DESC',
    );

    return result.map((e) => SapiModel.fromMap(e)).toList();
  }

  // ================= SEARCH SAPI =================
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

  // ================= GET PENGUKURAN BY SAPI =================
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

  // ================= GET SEMUA PENGUKURAN =================
  Future<List<PengukuranModel>> getAllPengukuran() async {
    final db = await database;

    final result = await db.query(
      'pengukuran',
      orderBy: 'id DESC',
    );

    return result.map((e) => PengukuranModel.fromMap(e)).toList();
  }

  // ================= DELETE SAPI =================
  Future<int> deleteSapi(int id) async {
    final db = await database;

    return await db.transaction((txn) async {
      // hapus semua riwayat/pengukuran sapi dulu
      await txn.delete(
        'pengukuran',
        where: 'sapi_id = ?',
        whereArgs: [id],
      );

      // baru hapus data sapinya
      return await txn.delete(
        'sapi',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ================= DELETE PENGUKURAN =================
  Future<int> deletePengukuran(int id) async {
    final db = await database;

    return await db.delete(
      'pengukuran',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= CLOSE DB =================
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}