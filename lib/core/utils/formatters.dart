/// أدوات تنسيق الأرقام والتواريخ بالعربية.
/// مكتوبة يدوياً بلا اعتماد على حزم خارجية لتفادي أي تعارض في الإصدارات.
class Fmt {
  static const List<String> arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static const List<String> arabicDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];

  /// إضافة فواصل الآلاف
  static String _group(String digits) {
    final buf = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// مبلغ بدون عملة — منزلتان عشريتان بحد أقصى مع حذف الأصفار الزائدة
  static String num2(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    final negative = v < 0;
    var s = v.abs().toStringAsFixed(2);

    if (s.endsWith('.00')) {
      s = s.substring(0, s.length - 3);
    } else if (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }

    final dot = s.indexOf('.');
    final intPart = dot == -1 ? s : s.substring(0, dot);
    final decPart = dot == -1 ? '' : s.substring(dot);
    final out = '${_group(intPart)}$decPart';
    return negative ? '-$out' : out;
  }

  /// عدد صحيح مع فواصل الآلاف
  static String count(num v) {
    final negative = v < 0;
    final s = _group(v.abs().round().toString());
    return negative ? '-$s' : s;
  }

  /// مبلغ مع رمز العملة
  static String money(double v, String currency) => '${num2(v)} $currency';

  /// تاريخ قصير: 2026/08/18
  static String date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  /// تاريخ مع اسم اليوم: الثلاثاء 18 أغسطس 2026
  static String dateWithDay(DateTime d) =>
      '${arabicDays[d.weekday - 1]} ${d.day} ${arabicMonths[d.month - 1]} ${d.year}';

  /// تاريخ طويل: 18 أغسطس 2026
  static String dateLong(DateTime d) =>
      '${d.day} ${arabicMonths[d.month - 1]} ${d.year}';

  /// اسم اليوم فقط
  static String dayName(DateTime d) => arabicDays[d.weekday - 1];

  /// وقت بنظام 12 ساعة بالعربية
  static String time(DateTime d) {
    final period = d.hour < 12 ? 'ص' : 'م';
    var h = d.hour % 12;
    if (h == 0) h = 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} $period';
  }

  static String dateTime(DateTime d) => '${date(d)} - ${time(d)}';

  /// نسبة مئوية
  static String percent(double v) => '${num2(v)}%';

  /// اسم الشهر والسنة
  static String monthYear(DateTime d) => '${arabicMonths[d.month - 1]} ${d.year}';

  /// تحويل نص إلى رقم مع دعم الأرقام العربية والفواصل
  static double parseNum(String? input) {
    if (input == null) return 0;
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    final buf = StringBuffer();

    for (final ch in input.trim().split('')) {
      final ai = arabicDigits.indexOf(ch);
      final pi = persianDigits.indexOf(ch);
      if (ai >= 0) {
        buf.write(ai.toString());
      } else if (pi >= 0) {
        buf.write(pi.toString());
      } else if (RegExp(r'[0-9.\-]').hasMatch(ch)) {
        buf.write(ch);
      } else if (ch == '٫') {
        buf.write('.');
      }
      // فواصل الآلاف تُتجاهل
    }
    return double.tryParse(buf.toString()) ?? 0;
  }
}
