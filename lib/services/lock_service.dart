import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../core/constants/app_info.dart';
import '../repositories/settings_repository.dart';

/// خدمة حماية الأقسام المالية بكلمة مرور / PIN
class LockService {
  final SettingsRepository _settings = SettingsRepository();

  static const String _salt = 'tsm_v1_';

  String hashPin(String pin) =>
      sha256.convert(utf8.encode('$_salt$pin')).toString();

  Future<bool> isEnabled() async =>
      (await _settings.get(SettingKeys.lockEnabled)) == '1';

  Future<int> pinLength() async =>
      int.tryParse(await _settings.get(SettingKeys.pinLength) ?? '4') ?? 4;

  Future<void> enable(String pin, int length) async {
    await _settings.setMany({
      SettingKeys.lockEnabled: '1',
      SettingKeys.pinHash: hashPin(pin),
      SettingKeys.pinLength: length.toString(),
    });
  }

  Future<void> disable() async {
    await _settings.setMany({
      SettingKeys.lockEnabled: '0',
      SettingKeys.pinHash: '',
    });
  }

  Future<bool> verify(String pin) async {
    final stored = await _settings.get(SettingKeys.pinHash);
    if (stored == null || stored.isEmpty) return true;
    return stored == hashPin(pin);
  }

  Future<bool> changePin(String oldPin, String newPin, int length) async {
    if (!await verify(oldPin)) return false;
    await enable(newPin, length);
    return true;
  }
}
