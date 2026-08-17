import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';

/// نتيجة عملية نسخ/استعادة
class BackupResult {
  final bool success;
  final String message;
  final String? path;
  const BackupResult(this.success, this.message, {this.path});
}

/// خدمة النسخ الاحتياطي والاستعادة (JSON + نسخ قاعدة البيانات)
class BackupService {
  final AppDatabase _db = AppDatabase.instance;

  static const List<String> _tables = [
    'persons',
    'work_entries',
    'money_txns',
    'expenses',
    'app_settings',
    'activity_logs',
    'counters',
  ];

  Future<Directory> _backupDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final b = Directory(p.join(dir.path, 'backups'));
    if (!await b.exists()) await b.create(recursive: true);
    return b;
  }

  String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }

  /// إنشاء نسخة احتياطية بصيغة JSON
  Future<BackupResult> createBackup({String? targetDirectory}) async {
    try {
      final db = await _db.database;
      final data = <String, dynamic>{
        'app': 'tailor_shop_manager',
        'version': AppDatabase.dbVersion,
        'created_at': DateTime.now().toIso8601String(),
        'tables': <String, dynamic>{},
      };

      for (final t in _tables) {
        data['tables'][t] = await db.query(t);
      }

      final dir = targetDirectory != null
          ? Directory(targetDirectory)
          : await _backupDir();
      if (!await dir.exists()) await dir.create(recursive: true);

      final file = File(p.join(dir.path, 'backup_${_stamp()}.json'));
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      return BackupResult(true, 'تم إنشاء النسخة الاحتياطية بنجاح', path: file.path);
    } catch (e) {
      return BackupResult(false, 'فشل إنشاء النسخة الاحتياطية: $e');
    }
  }

  /// اختيار مجلد لحفظ النسخة
  Future<String?> pickDirectory() async {
    try {
      return await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
      );
    } catch (_) {
      return null;
    }
  }

  /// استعادة من ملف JSON
  Future<BackupResult> restoreFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return const BackupResult(false, 'الملف غير موجود');
      }
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final tables = raw['tables'] as Map<String, dynamic>?;
      if (tables == null) {
        return const BackupResult(false, 'صيغة الملف غير صحيحة');
      }

      final db = await _db.database;
      await db.transaction((txn) async {
        // الحذف بترتيب عكسي لاحترام المفاتيح الأجنبية
        for (final t in _tables.reversed) {
          await txn.delete(t);
        }
        for (final t in _tables) {
          final rows = (tables[t] as List?) ?? const [];
          final batch = txn.batch();
          for (final r in rows) {
            batch.insert(t, Map<String, Object?>.from(r as Map),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit(noResult: true);
        }
      });

      return const BackupResult(true, 'تمت استعادة النسخة الاحتياطية بنجاح');
    } catch (e) {
      return BackupResult(false, 'فشل استعادة النسخة: $e');
    }
  }

  /// اختيار ملف نسخة واستعادته
  Future<BackupResult> pickAndRestore() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
      );
      final path = res?.files.single.path;
      if (path == null) return const BackupResult(false, 'لم يتم اختيار ملف');
      return restoreFromFile(path);
    } catch (e) {
      return BackupResult(false, 'فشل اختيار الملف: $e');
    }
  }

  /// تصدير ملف قاعدة البيانات الخام
  Future<BackupResult> exportDatabaseFile() async {
    try {
      final dbPath = await _db.databasePath();
      final src = File(dbPath);
      if (!await src.exists()) {
        return const BackupResult(false, 'قاعدة البيانات غير موجودة');
      }
      final dir = await _backupDir();
      final dest = File(p.join(dir.path, 'tailor_shop_${_stamp()}.db'));
      await src.copy(dest.path);
      return BackupResult(true, 'تم تصدير قاعدة البيانات', path: dest.path);
    } catch (e) {
      return BackupResult(false, 'فشل التصدير: $e');
    }
  }

  /// استيراد ملف قاعدة بيانات كامل
  Future<BackupResult> importDatabaseFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'اختر ملف قاعدة البيانات',
      );
      final path = res?.files.single.path;
      if (path == null) return const BackupResult(false, 'لم يتم اختيار ملف');

      await _db.close();
      final dbPath = await _db.databasePath();
      await File(path).copy(dbPath);
      await _db.database; // إعادة الفتح
      return const BackupResult(true, 'تم استيراد قاعدة البيانات بنجاح');
    } catch (e) {
      return BackupResult(false, 'فشل الاستيراد: $e');
    }
  }

  /// قائمة النسخ المحفوظة محلياً
  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _backupDir();
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  Future<void> shareBackup(String path) async {
    await Share.shareXFiles([XFile(path)], subject: 'نسخة احتياطية - إدارة محل الخياطة');
  }

  Future<void> deleteBackup(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
