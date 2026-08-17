import 'enums.dart';

/// نموذج موحّد للخياط / القصاص / العامل
class Person {
  final int? id;
  final String refNo;
  final String name;
  final String? phone;
  final String? notes;
  final PersonType type;

  /// خاص بالعامل
  final String? jobTitle;
  final double monthlySalary;
  final bool hasCommission;
  final double commissionRate;

  /// السعر الافتراضي للوحدة (أجرة الثوب / أجرة القصة)
  final double defaultUnitPrice;

  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;

  const Person({
    this.id,
    required this.refNo,
    required this.name,
    this.phone,
    this.notes,
    required this.type,
    this.jobTitle,
    this.monthlySalary = 0,
    this.hasCommission = false,
    this.commissionRate = 0,
    this.defaultUnitPrice = 0,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'ref_no': refNo,
        'name': name,
        'phone': phone,
        'notes': notes,
        'type': type.code,
        'job_title': jobTitle,
        'monthly_salary': monthlySalary,
        'has_commission': hasCommission ? 1 : 0,
        'commission_rate': commissionRate,
        'default_unit_price': defaultUnitPrice,
        'is_pinned': isPinned ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Person.fromMap(Map<String, Object?> m) => Person(
        id: m['id'] as int?,
        refNo: (m['ref_no'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        phone: m['phone'] as String?,
        notes: m['notes'] as String?,
        type: PersonTypeX.fromCode((m['type'] as String?) ?? 'worker'),
        jobTitle: m['job_title'] as String?,
        monthlySalary: (m['monthly_salary'] as num?)?.toDouble() ?? 0,
        hasCommission: (m['has_commission'] as int? ?? 0) == 1,
        commissionRate: (m['commission_rate'] as num?)?.toDouble() ?? 0,
        defaultUnitPrice: (m['default_unit_price'] as num?)?.toDouble() ?? 0,
        isPinned: (m['is_pinned'] as int? ?? 0) == 1,
        isArchived: (m['is_archived'] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );

  Person copyWith({
    int? id,
    String? refNo,
    String? name,
    String? phone,
    String? notes,
    PersonType? type,
    String? jobTitle,
    double? monthlySalary,
    bool? hasCommission,
    double? commissionRate,
    double? defaultUnitPrice,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
  }) =>
      Person(
        id: id ?? this.id,
        refNo: refNo ?? this.refNo,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        type: type ?? this.type,
        jobTitle: jobTitle ?? this.jobTitle,
        monthlySalary: monthlySalary ?? this.monthlySalary,
        hasCommission: hasCommission ?? this.hasCommission,
        commissionRate: commissionRate ?? this.commissionRate,
        defaultUnitPrice: defaultUnitPrice ?? this.defaultUnitPrice,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
}
