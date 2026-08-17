import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'pdf_service.dart' show ReportData;

/// تصدير التقارير إلى ملف Excel
class ExcelService {
  Future<File> export(ReportData data, {String? fileName}) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    for (var si = 0; si < data.sections.length; si++) {
      final s = data.sections[si];
      final name = _safeSheetName(s.title, si);
      final sheet = excel[name];

      // عنوان القسم
      sheet.appendRow([TextCellValue(data.title)]);
      sheet.appendRow([TextCellValue('الفترة: ${data.periodLabel}')]);
      if (data.subject != null) {
        sheet.appendRow([TextCellValue(data.subject!)]);
      }
      sheet.appendRow([TextCellValue('')]);

      sheet.appendRow(s.headers.map((h) => TextCellValue(h)).toList());
      for (final r in s.rows) {
        sheet.appendRow(r.cells.map<CellValue>((c) {
          final n = double.tryParse(c.replaceAll(',', ''));
          return n != null ? DoubleCellValue(n) : TextCellValue(c);
        }).toList());
      }

      if (si == data.sections.length - 1 && data.summary.isNotEmpty) {
        sheet.appendRow([TextCellValue('')]);
        sheet.appendRow([TextCellValue('الملخص المالي')]);
        data.summary.forEach((k, v) {
          sheet.appendRow([TextCellValue(k), TextCellValue(v)]);
        });
      }
    }

    if (defaultSheet != null && excel.tables.length > 1) {
      excel.delete(defaultSheet);
    }

    final dir = await getApplicationDocumentsDirectory();
    final out = Directory(p.join(dir.path, 'reports'));
    if (!await out.exists()) await out.create(recursive: true);

    final name = fileName ?? 'report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(p.join(out.path, name));
    final bytes = excel.save();
    if (bytes != null) await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> exportAndShare(ReportData data, {String? fileName}) async {
    final file = await export(data, fileName: fileName);
    await Share.shareXFiles([XFile(file.path)], subject: data.title);
  }

  String _safeSheetName(String title, int index) {
    var t = title.replaceAll(RegExp(r'[\[\]\*\/\\\?\:]'), ' ').trim();
    if (t.isEmpty) t = 'ورقة';
    if (t.length > 28) t = t.substring(0, 28);
    return '$t ${index + 1}';
  }
}
