/// ملخص مالي لشخص واحد
class PersonSummary {
  final double workTotal; // إجمالي الأجور من العمل
  final int workCount; // عدد الأثواب/القصات
  final double withdrawals; // المسحوبات
  final double personalExpenses; // المصروفات الشخصية
  final double familyExpenses; // المصروفات العائلية
  final double commission; // النسبة
  final double salary; // الراتب المصروف
  final double bonus; // مكافآت

  const PersonSummary({
    this.workTotal = 0,
    this.workCount = 0,
    this.withdrawals = 0,
    this.personalExpenses = 0,
    this.familyExpenses = 0,
    this.commission = 0,
    this.salary = 0,
    this.bonus = 0,
  });

  /// إجمالي المستحقات قبل الخصم
  double get grossDue => workTotal + commission + salary + bonus;

  /// إجمالي الخصومات
  double get deductions => withdrawals + personalExpenses + familyExpenses;

  /// صافي المستحق
  double get netDue => grossDue - deductions;
}

/// ملخص لوحة التحكم
class DashboardSummary {
  final int tailorsCount;
  final int cuttersCount;
  final int workersCount;
  final double totalWages;
  final double totalWithdrawals;
  final double totalExpenses;
  final double netDue;
  final int todayOperations;

  const DashboardSummary({
    this.tailorsCount = 0,
    this.cuttersCount = 0,
    this.workersCount = 0,
    this.totalWages = 0,
    this.totalWithdrawals = 0,
    this.totalExpenses = 0,
    this.netDue = 0,
    this.todayOperations = 0,
  });
}

/// عنصر في آخر العمليات
class RecentOperation {
  final String refNo;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String kind; // work | txn | expense

  const RecentOperation({
    required this.refNo,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.kind,
  });
}

/// نقطة على رسم بياني
class ChartPoint {
  final String label;
  final double value;
  const ChartPoint(this.label, this.value);
}
