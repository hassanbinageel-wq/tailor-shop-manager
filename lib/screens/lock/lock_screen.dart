import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

/// شاشة إدخال كلمة المرور / PIN لحماية الأقسام المالية
class LockScreen extends StatefulWidget {
  final String title;
  final bool isSetup;
  final ValueChanged<String>? onSetupComplete;

  const LockScreen({
    super.key,
    this.title = 'أدخل كلمة المرور',
    this.isSetup = false,
    this.onSetupComplete,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;
  int _length = 4;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _length = s.pinLength;
  }

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final settings = context.read<SettingsProvider>();
    final pin = _pin.text.trim();

    if (pin.length != _length) {
      setState(() => _error = 'يجب أن تتكون كلمة المرور من $_length أرقام');
      return;
    }

    if (widget.isSetup) {
      if (_confirm.text.trim() != pin) {
        setState(() => _error = 'كلمتا المرور غير متطابقتين');
        return;
      }
      await settings.enableLock(pin, _length);
      if (!mounted) return;
      widget.onSetupComplete?.call(pin);
      Navigator.pop(context, true);
      return;
    }

    setState(() => _checking = true);
    final ok = await settings.verifyPin(pin);
    if (!mounted) return;
    setState(() => _checking = false);

    if (ok) {
      settings.markUnlocked();
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'كلمة المرور غير صحيحة';
        _pin.clear();
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? 'تعيين كلمة المرور' : 'حماية البيانات'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isSetup ? Icons.lock_reset_rounded : Icons.lock_rounded,
                    size: 44,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  widget.isSetup
                      ? 'اختر رقماً سرياً لحماية الأقسام المالية'
                      : 'هذا القسم محمي بكلمة مرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                if (widget.isSetup) ...[
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 4, label: Text('4 أرقام')),
                      ButtonSegment(value: 6, label: Text('6 أرقام')),
                    ],
                    selected: {_length},
                    onSelectionChanged: (s) => setState(() {
                      _length = s.first;
                      _pin.clear();
                      _confirm.clear();
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 18),
                ],

                TextField(
                  controller: _pin,
                  obscureText: _obscure,
                  keyboardType: TextInputType.number,
                  maxLength: _length,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    counterText: '',
                    errorText: _error,
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'إظهار' : 'إخفاء',
                      icon: Icon(_obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                if (widget.isSetup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: _obscureConfirm,
                    keyboardType: TextInputType.number,
                    maxLength: _length,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checking ? null : _submit,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(widget.isSetup ? 'حفظ' : 'دخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// بوابة الحماية — تُستدعى قبل فتح أي قسم محمي
class LockGate {
  /// ترجع true إذا سُمح بالدخول
  static Future<bool> guard(BuildContext context, {String? sectionName}) async {
    final settings = context.read<SettingsProvider>();
    if (!settings.lockEnabled) return true;
    if (settings.unlockedThisSession) return true;

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          title: sectionName == null ? 'أدخل كلمة المرور' : 'الدخول إلى $sectionName',
        ),
      ),
    );
    return ok ?? false;
  }
}
