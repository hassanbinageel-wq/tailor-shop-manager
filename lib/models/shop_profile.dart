import 'enums.dart';

/// بيانات المحل المستخدمة في كل التقارير والفواتير
class ShopProfile {
  final String shopName;
  final String phone;
  final String address;
  final String? logoPath;
  final String? stampPath;
  final String footerMessage;
  final LogoPosition logoPosition;
  final double logoSize;
  final String currency;

  const ShopProfile({
    this.shopName = 'محل الخياطة',
    this.phone = '',
    this.address = '',
    this.logoPath,
    this.stampPath,
    this.footerMessage = 'شكراً لتعاملكم معنا',
    this.logoPosition = LogoPosition.right,
    this.logoSize = 70,
    this.currency = 'ر.ي',
  });

  ShopProfile copyWith({
    String? shopName,
    String? phone,
    String? address,
    String? logoPath,
    bool clearLogo = false,
    String? stampPath,
    bool clearStamp = false,
    String? footerMessage,
    LogoPosition? logoPosition,
    double? logoSize,
    String? currency,
  }) =>
      ShopProfile(
        shopName: shopName ?? this.shopName,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
        stampPath: clearStamp ? null : (stampPath ?? this.stampPath),
        footerMessage: footerMessage ?? this.footerMessage,
        logoPosition: logoPosition ?? this.logoPosition,
        logoSize: logoSize ?? this.logoSize,
        currency: currency ?? this.currency,
      );

  Map<String, String> toMap() => {
        'shop_name': shopName,
        'shop_phone': phone,
        'shop_address': address,
        'logo_path': logoPath ?? '',
        'stamp_path': stampPath ?? '',
        'footer_message': footerMessage,
        'logo_position': logoPosition.code,
        'logo_size': logoSize.toString(),
        'currency': currency,
      };

  factory ShopProfile.fromMap(Map<String, String> m) => ShopProfile(
        shopName: (m['shop_name']?.isNotEmpty ?? false) ? m['shop_name']! : 'محل الخياطة',
        phone: m['shop_phone'] ?? '',
        address: m['shop_address'] ?? '',
        logoPath: (m['logo_path']?.isNotEmpty ?? false) ? m['logo_path'] : null,
        stampPath: (m['stamp_path']?.isNotEmpty ?? false) ? m['stamp_path'] : null,
        footerMessage: (m['footer_message']?.isNotEmpty ?? false)
            ? m['footer_message']!
            : 'شكراً لتعاملكم معنا',
        logoPosition: LogoPositionX.fromCode(m['logo_position'] ?? 'right'),
        logoSize: double.tryParse(m['logo_size'] ?? '70') ?? 70,
        currency: (m['currency']?.isNotEmpty ?? false) ? m['currency']! : 'ر.ي',
      );
}
