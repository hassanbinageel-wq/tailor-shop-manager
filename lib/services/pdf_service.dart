import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/formatters.dart';
import '../models/enums.dart';
import '../models/shop_profile.dart';

/// صف في جدول التقرير
class ReportRow {
  final List<String> cells;
  final bool isTotal;
  const ReportRow(this.cells, {this.isTotal = false});
}

/// قسم داخل التقرير (جدول + عنوان)
class ReportSection {
  final String title;
  final List<String> headers;
  final List<ReportRow> rows;
  final List<double>? columnWidths;

  const ReportSection({
    required this.title,
    required this.headers,
    required this.rows,
    this.columnWidths,
  });
}

/// بيانات التقرير الكاملة
class ReportData {
  final String title;
  final String reportNo;
  final String periodLabel;
  final String? subject; // اسم الخياط/القصاص/العامل
  final List<ReportSection> sections;
  final Map<String, String> summary; // المجاميع النهائية
  final String? note;

  const ReportData({
    required this.title,
    required this.reportNo,
    required this.periodLabel,
    this.subject,
    required this.sections,
    this.summary = const {},
    this.note,
  });
}

/// خدمة توليد تقارير وفواتير PDF احترافية بالعربية (RTL)
class PdfService {
  pw.Font? _regular;
  pw.Font? _bold;

  Future<void> _ensureFonts() async {
    if (_regular != null && _bold != null) return;
    _regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    _bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
  }

  Future<Uint8List?> _loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final f = File(path);
      if (!await f.exists()) return null;
      return await f.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static const PdfColor _primary = PdfColor.fromInt(0xFF6D4C2F);
  static const PdfColor _accent = PdfColor.fromInt(0xFFC9A227);
  static const PdfColor _headerBg = PdfColor.fromInt(0xFFF3EDE6);
  static const PdfColor _stripe = PdfColor.fromInt(0xFFFAF8F5);
  static const PdfColor _line = PdfColor.fromInt(0xFFD9CFC2);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6157);

  /// توليد مستند PDF
  Future<Uint8List> build(ReportData data, ShopProfile shop) async {
    await _ensureFonts();
    final logoBytes = await _loadImage(shop.logoPath);
    final stampBytes = await _loadImage(shop.stampPath);
    final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final stamp = stampBytes != null ? pw.MemoryImage(stampBytes) : null;

    final theme = pw.ThemeData.withFont(base: _regular!, bold: _bold!);
    final doc = pw.Document(
      title: data.title,
      author: shop.shopName,
      creator: 'إدارة محل الخياطة',
      theme: theme,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 34),
        textDirection: pw.TextDirection.rtl,
        theme: theme,
        header: (ctx) => ctx.pageNumber == 1
            ? _buildHeader(data, shop, logo)
            : _buildSmallHeader(data, shop),
        footer: (ctx) => _buildFooter(ctx, shop),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          ..._buildSections(data),
          if (data.summary.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildSummaryBox(data.summary),
          ],
          if (data.note != null && data.note!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNote(data.note!),
          ],
          if (stamp != null) ...[
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(stamp, height: 70),
                  pw.SizedBox(height: 4),
                  pw.Text('الختم / التوقيع',
                      style: const pw.TextStyle(fontSize: 8, color: _muted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ------------------------ الترويسة ------------------------

  pw.Widget _buildHeader(ReportData data, ShopProfile shop, pw.MemoryImage? logo) {
    final logoWidget = logo == null
        ? pw.SizedBox(width: shop.logoSize, height: shop.logoSize)
        : pw.Container(
            width: shop.logoSize,
            height: shop.logoSize,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              image: pw.DecorationImage(image: logo, fit: pw.BoxFit.contain),
            ),
          );

    final info = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(shop.shopName,
            style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold, color: _primary)),
        pw.SizedBox(height: 3),
        if (shop.phone.isNotEmpty)
          pw.Text('جوال: ${shop.phone}',
              style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
        if (shop.address.isNotEmpty)
          pw.Text(shop.address, style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
      ],
    );

    late final pw.Widget top;
    switch (shop.logoPosition) {
      case LogoPosition.center:
        top = pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            logoWidget,
            pw.SizedBox(height: 6),
            pw.Text(shop.shopName,
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold, color: _primary)),
            pw.SizedBox(height: 2),
            pw.Text(
              [
                if (shop.phone.isNotEmpty) 'جوال: ${shop.phone}',
                if (shop.address.isNotEmpty) shop.address,
              ].join('  •  '),
              style: const pw.TextStyle(fontSize: 9.5, color: _muted),
            ),
          ],
        );
        break;
      case LogoPosition.left:
        top = pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [logoWidget, info],
        );
        break;
      case LogoPosition.right:
        top = pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [info, logoWidget],
        );
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        top,
        pw.SizedBox(height: 10),
        pw.Container(height: 2.5, color: _accent),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: pw.BoxDecoration(
            color: _headerBg,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _line, width: 0.7),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(data.title,
                    style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: _primary)),
              ),
              if (data.subject != null && data.subject!.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(data.subject!,
                      style: pw.TextStyle(
                          fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
                ),
              ],
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _metaItem('رقم التقرير', data.reportNo),
                  _metaItem('الفترة', data.periodLabel),
                  _metaItem('التاريخ', Fmt.dateLong(DateTime.now())),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _metaItem(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.SizedBox(height: 1),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      );

  pw.Widget _buildSmallHeader(ReportData data, ShopProfile shop) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(shop.shopName,
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold, color: _primary)),
            pw.Text('${data.title} — ${data.reportNo}',
                style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
      );

  pw.Widget _buildFooter(pw.Context ctx, ShopProfile shop) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(shop.footerMessage,
                style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
            pw.Text('صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
          ],
        ),
      );

  // ------------------------ الأقسام ------------------------

  List<pw.Widget> _buildSections(ReportData data) {
    final out = <pw.Widget>[];
    for (final s in data.sections) {
      out.add(pw.SizedBox(height: 10));
      out.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(7),
              topRight: pw.Radius.circular(7),
            ),
          ),
          child: pw.Text(s.title,
              style: pw.TextStyle(
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        ),
      );
      out.add(_buildTable(s));
    }
    return out;
  }

  pw.Widget _buildTable(ReportSection s) {
    if (s.rows.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _line, width: 0.7)),
        child: pw.Center(
          child: pw.Text('لا توجد بيانات في هذه الفترة',
              style: const pw.TextStyle(fontSize: 10, color: _muted)),
        ),
      );
    }

    Map<int, pw.TableColumnWidth>? widths;
    if (s.columnWidths != null) {
      widths = {
        for (var i = 0; i < s.columnWidths!.length; i++)
          i: pw.FlexColumnWidth(s.columnWidths![i]),
      };
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: widths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: s.headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    child: pw.Text(h,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...s.rows.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: r.isTotal
                  ? _headerBg
                  : (i.isEven ? PdfColors.white : _stripe),
            ),
            children: r.cells
                .map((c) => pw.Padding(
                      padding:
                          const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      child: pw.Text(c,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight:
                                r.isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                          )),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }

  pw.Widget _buildSummaryBox(Map<String, String> summary) {
    final entries = summary.entries.toList();
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _accent, width: 1.2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(color: _headerBg),
            child: pw.Text('الملخص المالي',
                style: pw.TextStyle(
                    fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: _primary)),
          ),
          ...entries.asMap().entries.map((e) {
            final isLast = e.key == entries.length - 1;
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: pw.BoxDecoration(
                color: isLast ? _headerBg : PdfColors.white,
                border: const pw.Border(
                    top: pw.BorderSide(color: _line, width: 0.6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.value.key,
                      style: pw.TextStyle(
                          fontSize: isLast ? 11.5 : 10,
                          fontWeight:
                              isLast ? pw.FontWeight.bold : pw.FontWeight.normal)),
                  pw.Text(e.value.value,
                      style: pw.TextStyle(
                          fontSize: isLast ? 12.5 : 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: isLast ? _primary : PdfColors.black)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildNote(String note) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: _stripe,
          borderRadius: pw.BorderRadius.circular(7),
          border: pw.Border.all(color: _line, width: 0.7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ملاحظات:',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(note, style: const pw.TextStyle(fontSize: 9.5)),
          ],
        ),
      );

  // ------------------------ الإخراج ------------------------

  Future<File> saveToFile(Uint8List bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final out = Directory(p.join(dir.path, 'reports'));
    if (!await out.exists()) await out.create(recursive: true);
    final file = File(p.join(out.path, fileName));
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> share(Uint8List bytes, String fileName) async {
    final file = await saveToFile(bytes, fileName);
    await Share.shareXFiles([XFile(file.path)], subject: fileName);
  }

  Future<void> printDocument(Uint8List bytes, String name) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
  }
}
