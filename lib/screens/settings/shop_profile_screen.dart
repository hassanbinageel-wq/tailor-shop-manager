import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';

/// تخصيص التقارير والفواتير: الشعار، اسم المحل، بيانات التواصل، الختم، التذييل
class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _footer;
  late LogoPosition _position;
  late double _logoSize;

  @override
  void initState() {
    super.initState();
    final shop = context.read<SettingsProvider>().shop;
    _name = TextEditingController(text: shop.shopName);
    _phone = TextEditingController(text: shop.phone);
    _address = TextEditingController(text: shop.address);
    _footer = TextEditingController(text: shop.footerMessage);
    _position = shop.logoPosition;
    _logoSize = shop.logoSize;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _footer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = context.read<SettingsProvider>();
    await settings.saveShop(settings.shop.copyWith(
      shopName: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      footerMessage: _footer.text.trim(),
      logoPosition: _position,
      logoSize: _logoSize,
    ));
    if (!mounted) return;
    showSnack(context, 'تم حفظ بيانات المحل — ستظهر تلقائياً في كل التقارير');
    Navigator.pop(context);
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final settings = context.read<SettingsProvider>();
    final source = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(ctx, false),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final path = isLogo
        ? await settings.pickLogo(fromCamera: source)
        : await settings.pickStamp(fromCamera: source);

    if (path == null) return;
    if (isLogo) {
      await settings.setLogo(path);
    } else {
      await settings.setStamp(path);
    }
    if (mounted) showSnack(context, isLogo ? 'تم تحديث الشعار' : 'تم تحديث الختم');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final shop = settings.shop;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تخصيص التقارير والفواتير')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ---------- الشعار ----------
            const SectionHeader(title: 'شعار المحل', icon: Icons.image_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: shop.logoPath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 40, color: scheme.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text('لم يتم رفع شعار بعد',
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 13)),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.file(
                                File(shop.logoPath!),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Text('تعذّر عرض الشعار')),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _pickImage(isLogo: true),
                            icon: const Icon(Icons.upload_rounded),
                            label: Text(
                                shop.logoPath == null ? 'رفع شعار' : 'استبدال'),
                          ),
                        ),
                        if (shop.logoPath != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final ok = await confirmDialog(
                                  context,
                                  title: 'حذف الشعار',
                                  message: 'سيتم إزالة الشعار من كل التقارير.',
                                );
                                if (ok && context.mounted) {
                                  await settings.setLogo(null);
                                }
                              },
                              icon: const Icon(Icons.delete_rounded),
                              label: const Text('حذف'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------- موضع الشعار وحجمه ----------
            const SectionHeader(
                title: 'موضع الشعار وحجمه', icon: Icons.tune_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الموضع في التقرير',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    SegmentedButton<LogoPosition>(
                      segments: LogoPosition.values
                          .map((p) => ButtonSegment(
                                value: p,
                                label: Text(p.label),
                                icon: Icon(switch (p) {
                                  LogoPosition.right =>
                                    Icons.format_align_right_rounded,
                                  LogoPosition.center =>
                                    Icons.format_align_center_rounded,
                                  LogoPosition.left =>
                                    Icons.format_align_left_rounded,
                                }),
                              ))
                          .toList(),
                      selected: {_position},
                      onSelectionChanged: (s) =>
                          setState(() => _position = s.first),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('الحجم',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('${_logoSize.round()} pt',
                            style: TextStyle(
                                fontSize: 13, color: scheme.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Slider(
                      value: _logoSize,
                      min: 40,
                      max: 140,
                      divisions: 20,
                      label: '${_logoSize.round()}',
                      onChanged: (v) => setState(() => _logoSize = v),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- بيانات المحل ----------
            const SectionHeader(
                title: 'بيانات المحل', icon: Icons.storefront_rounded),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  AppField(
                    controller: _name,
                    label: 'اسم المحل',
                    icon: Icons.storefront_rounded,
                    required: true,
                  ),
                  AppField(
                    controller: _phone,
                    label: 'رقم الجوال',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  AppField(
                    controller: _address,
                    label: 'العنوان',
                    icon: Icons.location_on_rounded,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // ---------- الختم ----------
            const SectionHeader(
                title: 'ختم المحل أو توقيع المدير (اختياري)',
                icon: Icons.approval_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: shop.stampPath == null
                          ? Center(
                              child: Text('لا يوجد ختم',
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13)),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.file(File(shop.stampPath!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Center(child: Text('تعذّر العرض'))),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _pickImage(isLogo: false),
                            icon: const Icon(Icons.upload_rounded),
                            label: Text(
                                shop.stampPath == null ? 'رفع ختم' : 'استبدال'),
                          ),
                        ),
                        if (shop.stampPath != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => settings.setStamp(null),
                              icon: const Icon(Icons.delete_rounded),
                              label: const Text('حذف'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------- التذييل ----------
            const SectionHeader(
                title: 'رسالة أسفل التقرير', icon: Icons.short_text_rounded),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppField(
                controller: _footer,
                label: 'نص التذييل',
                hint: 'مثال: شكراً لتعاملكم معنا',
                icon: Icons.edit_note_rounded,
                maxLines: 2,
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ البيانات'),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                'بعد الحفظ ستُستخدم هذه البيانات تلقائياً في جميع التقارير والفواتير وملفات PDF دون الحاجة لإعادة إدخالها.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
