import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_info.dart';
import '../models/enums.dart';
import '../models/shop_profile.dart';
import '../repositories/settings_repository.dart';
import '../services/lock_service.dart';

/// مزوّد الإعدادات: السمة، العملة، بيانات المحل، الحماية، الإشعارات
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();
  final LockService lock = LockService();

  bool _loaded = false;
  bool get loaded => _loaded;

  AppThemeMode _themeMode = AppThemeMode.system;
  ShopProfile _shop = const ShopProfile();
  bool _lockEnabled = false;
  int _pinLength = 4;

  bool notifySalary = true;
  bool notifyBackup = true;
  bool notifyExpenseAlert = false;
  double expenseThreshold = 0;
  DateTime? lastBackupAt;

  /// جلسة الفتح الحالية — يُطلب PIN مرة واحدة لكل تشغيل
  bool _unlockedThisSession = false;
  bool get unlockedThisSession => _unlockedThisSession;
  void markUnlocked() {
    _unlockedThisSession = true;
    notifyListeners();
  }

  void lockSession() {
    _unlockedThisSession = false;
    notifyListeners();
  }

  AppThemeMode get themeMode => _themeMode;
  ShopProfile get shop => _shop;
  String get currency => _shop.currency;
  bool get lockEnabled => _lockEnabled;
  int get pinLength => _pinLength;

  ThemeMode get materialThemeMode => switch (_themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  Future<void> load() async {
    final all = await _repo.getAll();
    _themeMode = AppThemeModeX.fromCode(all[SettingKeys.themeMode] ?? 'system');
    _shop = ShopProfile.fromMap(all);
    _lockEnabled = all[SettingKeys.lockEnabled] == '1';
    _pinLength = int.tryParse(all[SettingKeys.pinLength] ?? '4') ?? 4;

    notifySalary = (all[SettingKeys.notifySalary] ?? '1') == '1';
    notifyBackup = (all[SettingKeys.notifyBackup] ?? '1') == '1';
    notifyExpenseAlert = (all[SettingKeys.notifyExpenseAlert] ?? '0') == '1';
    expenseThreshold = double.tryParse(all[SettingKeys.expenseThreshold] ?? '0') ?? 0;
    final lb = int.tryParse(all[SettingKeys.lastBackupAt] ?? '');
    lastBackupAt = lb == null ? null : DateTime.fromMillisecondsSinceEpoch(lb);

    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repo.set(SettingKeys.themeMode, mode.code);
  }

  Future<void> saveShop(ShopProfile profile) async {
    _shop = profile;
    notifyListeners();
    await _repo.setMany(profile.toMap());
  }

  Future<void> setCurrency(String currency) async {
    await saveShop(_shop.copyWith(currency: currency));
  }

  /// نسخ صورة مختارة إلى مجلد التطبيق لضمان بقائها
  Future<String?> _persistImage(XFile file, String prefix) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final brand = Directory(p.join(dir.path, 'branding'));
      if (!await brand.exists()) await brand.create(recursive: true);
      final ext = p.extension(file.path).isEmpty ? '.png' : p.extension(file.path);
      final dest = File(
          p.join(brand.path, '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext'));
      await dest.writeAsBytes(await file.readAsBytes());
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  /// رفع شعار المحل من الهاتف
  Future<String?> pickLogo({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (img == null) return null;
    return _persistImage(img, 'logo');
  }

  Future<String?> pickStamp({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (img == null) return null;
    return _persistImage(img, 'stamp');
  }

  Future<void> setLogo(String? path) async {
    _shop = path == null
        ? _shop.copyWith(clearLogo: true)
        : _shop.copyWith(logoPath: path);
    notifyListeners();
    await _repo.set(SettingKeys.logoPath, path ?? '');
  }

  Future<void> setStamp(String? path) async {
    _shop = path == null
        ? _shop.copyWith(clearStamp: true)
        : _shop.copyWith(stampPath: path);
    notifyListeners();
    await _repo.set(SettingKeys.stampPath, path ?? '');
  }

  Future<void> setLogoPosition(LogoPosition pos) async {
    _shop = _shop.copyWith(logoPosition: pos);
    notifyListeners();
    await _repo.set(SettingKeys.logoPosition, pos.code);
  }

  Future<void> setLogoSize(double size) async {
    _shop = _shop.copyWith(logoSize: size);
    notifyListeners();
    await _repo.set(SettingKeys.logoSize, size.toString());
  }

  // ------------------- الحماية -------------------

  Future<void> enableLock(String pin, int length) async {
    await lock.enable(pin, length);
    _lockEnabled = true;
    _pinLength = length;
    _unlockedThisSession = true;
    notifyListeners();
  }

  Future<void> disableLock() async {
    await lock.disable();
    _lockEnabled = false;
    _unlockedThisSession = true;
    notifyListeners();
  }

  Future<bool> changePin(String oldPin, String newPin, int length) async {
    final ok = await lock.changePin(oldPin, newPin, length);
    if (ok) {
      _pinLength = length;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> verifyPin(String pin) => lock.verify(pin);

  // ------------------- الإشعارات -------------------

  Future<void> setNotifySalary(bool v) async {
    notifySalary = v;
    notifyListeners();
    await _repo.set(SettingKeys.notifySalary, v ? '1' : '0');
  }

  Future<void> setNotifyBackup(bool v) async {
    notifyBackup = v;
    notifyListeners();
    await _repo.set(SettingKeys.notifyBackup, v ? '1' : '0');
  }

  Future<void> setNotifyExpenseAlert(bool v) async {
    notifyExpenseAlert = v;
    notifyListeners();
    await _repo.set(SettingKeys.notifyExpenseAlert, v ? '1' : '0');
  }

  Future<void> setExpenseThreshold(double v) async {
    expenseThreshold = v;
    notifyListeners();
    await _repo.set(SettingKeys.expenseThreshold, v.toString());
  }

  Future<void> markBackupDone() async {
    lastBackupAt = DateTime.now();
    notifyListeners();
    await _repo.set(
        SettingKeys.lastBackupAt, lastBackupAt!.millisecondsSinceEpoch.toString());
  }
}
