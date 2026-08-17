import 'package:intl/intl.dart';

/// أدوات تنسيق الأرقام والتواريخ بالعربية
class Fmt {
  static final NumberFormat _money = NumberFormat('#,##0.##', 'en_US');
  static final NumberFormat _int = NumberFormat('#,##0', 'en_US');

  static const List<String> arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static const List<String> arabicDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];

  /// مبلغ بدون عملة
  static String num2(double v) => _money.format(v);

  /// عدد صحيح
  static String count(num v) => _int.format(v);

  /// مبلغ مع رمز العملة
  static String money(double v, String currency) => '${_money.format(v)} $currency';

  /// تاريخ قصير: 2026/08/16
  static String date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  /// تاريخ مع اسم اليوم: الأحد 16 أغسطس 2026
  static String dateWithDay(DateTime d) =>
      '${arabicDays[d.weekday - 1]} ${d.day} ${arabicMonths[d.month - 1]} ${d.year}';

  /// تاريخ طويل: 16 أغسطس 2026
  static String dateLong(DateTime d) => '${d.day} ${arabicMonths[d.month - 1]} ${d.year}';

  /// اسم اليوم فقط
  static String dayName(DateTime d) => arabicDays[d.weekday - 1];

  /// وقت 12 ساعة بالعربية
  static String time(DateTime d) {
    final h24 = d.hour;
    final period = h24 < 12 ? 'ص' : 'م';
    var h = h24 % 12;
    if (h == 0) h = 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} $period';
  }

  static String dateTime(DateTime d) => '${date(d)} - ${time(d)}';

  /// نسبة مئوية
  static String percent(double v) => '${_money.format(v)}%';

  /// اسم الشهر والسنة
  static String monthYear(DateTime d) => '${arabicMonths[d.month - 1]} ${d.year}';

  /// تحويل نص إلى رقم مع دعم الأرقام العربية والفواصل
  static double parseNum(String? input) {
    if (input == null) return 0;
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (final ch in input.trim().split('')) {
      final ai = arabicDigits.indexOf(ch);
      if (ai >= 0) {
        buf.write(ai.toString());
      } else if (RegExp(r'[0-9.\-]').hasMatch(ch)) {
        buf.write(ch);
      } else if (ch == '٫' || ch == ',') {
        // تجاهل فاصل الآلاف، وتحويل الفاصلة العشرية العربية
        if (ch == '٫') buf.write('.');
      }
    }
    return double.tryParse(buf.toString()) ?? 0;
  }
}
