import 'enums.dart';

/// حركة مالية مرتبطة بشخص (مسحوبات، مصروفات شخصية/عائلية، نسبة، راتب)
class MoneyTxn {
  final int? id;
  final String refNo;
  final int personId;
  final PersonType personType;
  final TxnKind kind;
  final DateTime date;
  final double amount;
  final String? notes;
  final String? attachmentPath;
  final DateTime createdAt;

  const MoneyTxn({
    this.id,
    required this.refNo,
    required this.personId,
    required this.personType,
    required this.kind,
    required this.date,
    required this.amount,
    this.notes,
    this.attachmentPath,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'ref_no': refNo,
        'person_id': personId,
        'person_type': personType.code,
        'kind': kind.code,
        'date': date.millisecondsSinceEpoch,
        'amount': amount,
        'notes': notes,
        'attachment_path': attachmentPath,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory MoneyTxn.fromMap(Map<String, Object?> m) => MoneyTxn(
        id: m['id'] as int?,
        refNo: (m['ref_no'] as String?) ?? '',
        personId: (m['person_id'] as int?) ?? 0,
        personType: PersonTypeX.fromCode((m['person_type'] as String?) ?? 'worker'),
        kind: TxnKindX.fromCode((m['kind'] as String?) ?? 'withdrawal'),
        date: DateTime.fromMillisecondsSinceEpoch((m['date'] as int?) ?? 0),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        notes: m['notes'] as String?,
        attachmentPath: m['attachment_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );

  MoneyTxn copyWith({
    int? id,
    String? refNo,
    int? personId,
    PersonType? personType,
    TxnKind? kind,
    DateTime? date,
    double? amount,
    String? notes,
    String? attachmentPath,
    DateTime? createdAt,
  }) =>
      MoneyTxn(
        id: id ?? this.id,
        refNo: refNo ?? this.refNo,
        personId: personId ?? this.personId,
        personType: personType ?? this.personType,
        kind: kind ?? this.kind,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        notes: notes ?? this.notes,
        attachmentPath: attachmentPath ?? this.attachmentPath,
        createdAt: createdAt ?? this.createdAt,
      );
}
