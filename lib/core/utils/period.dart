import '../../models/enums.dart';

/// نطاق زمني للفلترة والتقارير
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);

  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;

  bool contains(DateTime d) =>
      !d.isBefore(start) && !d.isAfter(end);
}

class Periods {
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  /// بداية الأسبوع (السبت — التقويم العربي الشائع)
  static DateTime startOfWeek(DateTime d) {
    final wd = d.weekday; // 1=الاثنين .. 7=الأحد
    final daysSinceSaturday = (wd + 1) % 7; // السبت = 6 -> 0
    return startOfDay(d.subtract(Duration(days: daysSinceSaturday)));
  }

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);

  static DateTime startOfYear(DateTime d) => DateTime(d.year, 1, 1);
  static DateTime endOfYear(DateTime d) => DateTime(d.year, 12, 31, 23, 59, 59, 999);

  /// نطاق زمني حسب نوع الفترة
  static DateRange rangeFor(PeriodType type,
      {DateTime? now, DateTime? customStart, DateTime? customEnd}) {
    final n = now ?? DateTime.now();
    switch (type) {
      case PeriodType.today:
        return DateRange(startOfDay(n), endOfDay(n));
      case PeriodType.week:
        return DateRange(startOfWeek(n), endOfDay(n));
      case PeriodType.month:
        return DateRange(startOfMonth(n), endOfMonth(n));
      case PeriodType.year:
        return DateRange(startOfYear(n), endOfYear(n));
      case PeriodType.all:
        return DateRange(DateTime(2000), DateTime(2100));
      case PeriodType.custom:
        return DateRange(
          startOfDay(customStart ?? startOfMonth(n)),
          endOfDay(customEnd ?? n),
        );
    }
  }

  /// آخر 6 أشهر (للمقارنة الشهرية)
  static List<DateTime> lastMonths(int count, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return List.generate(count, (i) => DateTime(n.year, n.month - (count - 1 - i), 1));
  }

  /// آخر 7 أيام
  static List<DateTime> lastDays(int count, {DateTime? now}) {
    final n = startOfDay(now ?? DateTime.now());
    return List.generate(count, (i) => n.subtract(Duration(days: count - 1 - i)));
  }
}
