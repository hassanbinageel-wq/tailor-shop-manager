/// معلومات ثابتة عن التطبيق
class AppInfo {
  static const String name = 'إدارة محل الخياطة';
  static const String version = '1.0.0';
  static const String developer = 'hsn.pmt';
  static const String description =
      'تطبيق متكامل لإدارة محلات الخياطة الرجالية: متابعة الخياطين والقصاصين '
      'والعاملين، تسجيل الأجور والمسحوبات والمصروفات، وإصدار تقارير وفواتير '
      'احترافية بصيغة PDF. يعمل بالكامل بدون إنترنت.';

  /// بادئات الأرقام المرجعية
  static const String refWork = 'WRK';
  static const String refTxn = 'TXN';
  static const String refExpense = 'EXP';
  static const String refPerson = 'PRS';
  static const String refReport = 'RPT';
}

/// مفاتيح الإعدادات المخزنة
class SettingKeys {
  static const String themeMode = 'theme_mode';
  static const String currency = 'currency';
  static const String shopName = 'shop_name';
  static const String shopPhone = 'shop_phone';
  static const String shopAddress = 'shop_address';
  static const String logoPath = 'logo_path';
  static const String stampPath = 'stamp_path';
  static const String footerMessage = 'footer_message';
  static const String logoPosition = 'logo_position';
  static const String logoSize = 'logo_size';

  static const String lockEnabled = 'lock_enabled';
  static const String pinHash = 'pin_hash';
  static const String pinLength = 'pin_length';

  static const String notifySalary = 'notify_salary';
  static const String notifyBackup = 'notify_backup';
  static const String notifyExpenseAlert = 'notify_expense_alert';
  static const String expenseThreshold = 'expense_threshold';
  static const String lastBackupAt = 'last_backup_at';
}
