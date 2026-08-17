import 'package:sqflite/sqflite.dart';

import '../core/constants/app_info.dart';
import '../core/db/app_database.dart';
import '../models/enums.dart';
import '../models/person.dart';

class PersonRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Person>> getByType(PersonType type,
      {String? query, bool includeArchived = false}) async {
    final db = await _db.database;
    final where = StringBuffer('type = ?');
    final args = <Object?>[type.code];

    if (!includeArchived) where.write(' AND is_archived = 0');

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      where.write(' AND (name LIKE ? OR phone LIKE ? OR ref_no LIKE ? OR job_title LIKE ?)');
      args.addAll([q, q, q, q]);
    }

    final rows = await db.query(
      'persons',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'is_pinned DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Person.fromMap).toList();
  }

  Future<List<Person>> getAll({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'persons',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'type ASC, is_pinned DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Person.fromMap).toList();
  }

  Future<Person?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('persons', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Person.fromMap(rows.first);
  }

  Future<int> countByType(PersonType type) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM persons WHERE type = ? AND is_archived = 0',
      [type.code],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> insert(Person person) async {
    final db = await _db.database;
    final ref = person.refNo.isEmpty ? await _db.nextRef(AppInfo.refPerson) : person.refNo;
    return db.insert('persons', person.copyWith(refNo: ref).toMap());
  }

  Future<int> update(Person person) async {
    final db = await _db.database;
    return db.update('persons', person.toMap(),
        where: 'id = ?', whereArgs: [person.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> setPinned(int id, bool pinned) async {
    final db = await _db.database;
    return db.update('persons', {'is_pinned': pinned ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> setArchived(int id, bool archived) async {
    final db = await _db.database;
    return db.update('persons', {'is_archived': archived ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// بحث عام بالاسم أو الجوال
  Future<List<Person>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      'persons',
      where: 'name LIKE ? OR phone LIKE ? OR ref_no LIKE ? OR job_title LIKE ?',
      whereArgs: [q, q, q, q],
      orderBy: 'name COLLATE NOCASE ASC',
      limit: 50,
    );
    return rows.map(Person.fromMap).toList();
  }
}
