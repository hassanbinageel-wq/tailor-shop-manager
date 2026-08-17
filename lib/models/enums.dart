/// أنواع الأشخاص في المحل
enum PersonType { tailor, cutter, worker }

extension PersonTypeX on PersonType {
  String get code => switch (this) {
        PersonType.tailor => 'tailor',
        PersonType.cutter => 'cutter',
        PersonType.worker => 'worker',
      };

  /// الاسم المفرد
  String get label => switch (this) {
        PersonType.tailor => 'خياط',
        PersonType.cutter => 'قصاص',
        PersonType.worker => 'عامل',
      };

  /// الاسم بصيغة الجمع
  String get labelPlural => switch (this) {
        PersonType.tailor => 'الخياطون',
        PersonType.cutter => 'القصاصون',
        PersonType.worker => 'العاملون',
      };

  /// اسم وحدة العمل (ثوب / قصة)
  String get unitLabel => switch (this) {
        PersonType.tailor => 'ثوب',
        PersonType.cutter => 'قصة',
        PersonType.worker => 'عملية',
      };

  String get unitPluralLabel => switch (this) {
        PersonType.tailor => 'الأثواب',
        PersonType.cutter => 'القصات',
        PersonType.worker => 'العمليات',
      };

  static PersonType fromCode(String code) => switch (code) {
        'tailor' => PersonType.tailor,
        'cutter' => PersonType.cutter,
        _ => PersonType.worker,
      };
}

/// أنواع الحركات المالية المرتبطة بشخص
enum TxnKind { withdrawal, personalExpense, familyExpense, commission, salary, bonus }

extension TxnKindX on TxnKind {
  String get code => switch (this) {
        TxnKind.withdrawal => 'withdrawal',
        TxnKind.personalExpense => 'personal_expense',
        TxnKind.familyExpense => 'family_expense',
        TxnKind.commission => 'commission',
        TxnKind.salary => 'salary',
        TxnKind.bonus => 'bonus',
      };

  String get label => switch (this) {
        TxnKind.withdrawal => 'مسحوبات',
        TxnKind.personalExpense => 'مصروفات شخصية',
        TxnKind.familyExpense => 'مصروفات عائلية',
        TxnKind.commission => 'نسبة',
        TxnKind.salary => 'راتب',
        TxnKind.bonus => 'مكافأة',
      };

  static TxnKind fromCode(String code) => switch (code) {
        'withdrawal' => TxnKind.withdrawal,
        'personal_expense' => TxnKind.personalExpense,
        'family_expense' => TxnKind.familyExpense,
        'commission' => TxnKind.commission,
        'salary' => TxnKind.salary,
        _ => TxnKind.bonus,
      };
}

/// الفترات الزمنية للفلترة
enum PeriodType { today, week, month, year, all, custom }

extension PeriodTypeX on PeriodType {
  String get label => switch (this) {
        PeriodType.today => 'اليوم',
        PeriodType.week => 'الأسبوع',
        PeriodType.month => 'الشهر',
        PeriodType.year => 'السنة',
        PeriodType.all => 'الكل',
        PeriodType.custom => 'فترة مخصصة',
      };
}

/// موضع الشعار في التقارير
enum LogoPosition { right, center, left }

extension LogoPositionX on LogoPosition {
  String get code => switch (this) {
        LogoPosition.right => 'right',
        LogoPosition.center => 'center',
        LogoPosition.left => 'left',
      };

  String get label => switch (this) {
        LogoPosition.right => 'يمين',
        LogoPosition.center => 'وسط',
        LogoPosition.left => 'يسار',
      };

  static LogoPosition fromCode(String code) => switch (code) {
        'center' => LogoPosition.center,
        'left' => LogoPosition.left,
        _ => LogoPosition.right,
      };
}

/// وضع السمة
enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  String get code => switch (this) {
        AppThemeMode.light => 'light',
        AppThemeMode.dark => 'dark',
        AppThemeMode.system => 'system',
      };

  String get label => switch (this) {
        AppThemeMode.light => 'الوضع الفاتح',
        AppThemeMode.dark => 'الوضع الداكن',
        AppThemeMode.system => 'اتباع إعدادات النظام',
      };

  static AppThemeMode fromCode(String code) => switch (code) {
        'light' => AppThemeMode.light,
        'dark' => AppThemeMode.dark,
        _ => AppThemeMode.system,
      };
}
