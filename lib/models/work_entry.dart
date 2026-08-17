import 'enums.dart';

/// عملية عمل: عدد أثواب × أجرة الثوب  /  عدد قصات × أجرة القصة
class WorkEntry {
  final int? id;
  final String refNo;
  final int personId;
  final PersonType personType;
  final DateTime date;
  final double quantity;
  final double unitPrice;
  final String? notes;
  final String? attachmentPath;
  final DateTime createdAt;

  const WorkEntry({
    this.id,
    required this.refNo,
    required this.personId,
    required this.personType,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    this.attachmentPath,
    required this.createdAt,
  });

  /// الإجمالي المحتسب تلقائياً
  double get total => quantity * unitPrice;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'ref_no': refNo,
        'person_id': personId,
        'person_type': personType.code,
        'date': date.millisecondsSinceEpoch,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
        'notes': notes,
        'attachment_path': attachmentPath,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory WorkEntry.fromMap(Map<String, Object?> m) => WorkEntry(
        id: m['id'] as int?,
        refNo: (m['ref_no'] as String?) ?? '',
        personId: (m['person_id'] as int?) ?? 0,
        personType: PersonTypeX.fromCode((m['person_type'] as String?) ?? 'tailor'),
        date: DateTime.fromMillisecondsSinceEpoch((m['date'] as int?) ?? 0),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
        notes: m['notes'] as String?,
        attachmentPath: m['attachment_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );

  WorkEntry copyWith({
    int? id,
    String? refNo,
    int? personId,
    PersonType? personType,
    DateTime? date,
    double? quantity,
    double? unitPrice,
    String? notes,
    String? attachmentPath,
    DateTime? createdAt,
  }) =>
      WorkEntry(
        id: id ?? this.id,
        refNo: refNo ?? this.refNo,
        personId: personId ?? this.personId,
        personType: personType ?? this.personType,
        date: date ?? this.date,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        notes: notes ?? this.notes,
        attachmentPath: attachmentPath ?? this.attachmentPath,
        createdAt: createdAt ?? this.createdAt,
      );
}
