import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common.dart';

/// معاينة التقرير مع خيارات التصدير والمشاركة والطباعة
class ReportPreviewScreen extends StatefulWidget {
  final ReportData data;
  const ReportPreviewScreen({super.key, required this.data});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  bool _working = false;

  Future<Uint8List> _build() {
    final settings = context.read<SettingsProvider>();
    final reports = context.read<ReportProvider>();
    return reports.renderPdf(widget.data, settings.shop);
  }

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _working = true);
    try {
      await action();
      if (mounted) showSnack(context, successMessage);
    } catch (e) {
      if (mounted) showSnack(context, 'حدث خطأ: $e', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.read<ReportProvider>();
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data.title),
        actions: [
          IconButton(
            tooltip: 'مشاركة PDF',
            icon: const Icon(Icons.share_rounded),
            onPressed: _working
                ? null
                : () => _run(
                    () => reports.sharePdf(widget.data, settings.shop),
                    'تمت المشاركة'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              switch (v) {
                case 'print':
                  _run(() => reports.printPdf(widget.data, settings.shop),
                      'تم إرسال المستند للطباعة');
                case 'excel':
                  _run(() => reports.shareExcel(widget.data),
                      'تم تصدير ملف Excel');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'print',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.print_rounded),
                  title: Text('طباعة'),
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.table_chart_rounded),
                  title: Text('تصدير Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_working) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: PdfPreview(
              build: (_) => _build(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              pdfFileName: reports.fileName(widget.data, 'pdf'),
              loadingWidget: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
