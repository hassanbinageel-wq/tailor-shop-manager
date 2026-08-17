import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// مدير قاعدة البيانات المحلية (SQLite) — يعمل بالكامل بدون إنترنت
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String dbName = 'tailor_shop.db';
  static const int dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<String> databasePath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, dbName);
  }

  Future<Database> _open() async {
    final path = await databasePath();
    return openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref_no TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        type TEXT NOT NULL,
        job_title TEXT,
        monthly_salary REAL NOT NULL DEFAULT 0,
        has_commission INTEGER NOT NULL DEFAULT 0,
        commission_rate REAL NOT NULL DEFAULT 0,
        default_unit_price REAL NOT NULL DEFAULT 0,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE work_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref_no TEXT NOT NULL,
        person_id INTEGER NOT NULL,
        person_type TEXT NOT NULL,
        date INTEGER NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        unit_price REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        notes TEXT,
        attachment_path TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE money_txns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref_no TEXT NOT NULL,
        person_id INTEGER NOT NULL,
        person_type TEXT NOT NULL,
        kind TEXT NOT NULL,
        date INTEGER NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        notes TEXT,
        attachment_path TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref_no TEXT NOT NULL,
        date INTEGER NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        description TEXT,
        notes TEXT,
        attachment_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id INTEGER,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE counters (
        name TEXT PRIMARY KEY,
        value INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // فهارس لدعم آلاف السجلات بأداء عالٍ
    batch.execute('CREATE INDEX idx_persons_type ON persons (type, is_archived)');
    batch.execute('CREATE INDEX idx_persons_name ON persons (name)');
    batch.execute('CREATE INDEX idx_work_person ON work_entries (person_id, date)');
    batch.execute('CREATE INDEX idx_work_date ON work_entries (date)');
    batch.execute('CREATE INDEX idx_work_type ON work_entries (person_type, date)');
    batch.execute('CREATE INDEX idx_txn_person ON money_txns (person_id, kind, date)');
    batch.execute('CREATE INDEX idx_txn_date ON money_txns (date)');
    batch.execute('CREATE INDEX idx_txn_type ON money_txns (person_type, kind, date)');
    batch.execute('CREATE INDEX idx_expense_date ON expenses (date)');
    batch.execute('CREATE INDEX idx_expense_cat ON expenses (category, date)');
    batch.execute('CREATE INDEX idx_logs_time ON activity_logs (timestamp)');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // مخصّص للترقيات المستقبلية للمخطط
  }

  /// توليد رقم مرجعي تلقائي لكل عملية
  Future<String> nextRef(String prefix) async {
    final db = await database;
    return db.transaction<String>((txn) async {
      final rows = await txn.query('counters', where: 'name = ?', whereArgs: [prefix]);
      int next = 1;
      if (rows.isEmpty) {
        await txn.insert('counters', {'name': prefix, 'value': 1});
      } else {
        next = ((rows.first['value'] as int?) ?? 0) + 1;
        await txn.update('counters', {'value': next}, where: 'name = ?', whereArgs: [prefix]);
      }
      return '$prefix-${next.toString().padLeft(5, '0')}';
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// حذف كل البيانات (تصفير كامل)
  Future<void> wipeAll() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('work_entries');
    batch.delete('money_txns');
    batch.delete('expenses');
    batch.delete('persons');
    batch.delete('activity_logs');
    batch.delete('counters');
    await batch.commit(noResult: true);
  }

  /// مجلد المرفقات داخل التطبيق
  Future<Directory> attachmentsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final att = Directory(p.join(dir.path, 'attachments'));
    if (!await att.exists()) await att.create(recursive: true);
    return att;
  }
}
