/// تصنيفات المصروفات العامة للمحل
class ExpenseCategory {
  static const String rent = 'إيجار';
  static const String electricity = 'كهرباء';
  static const String water = 'ماء';
  static const String tools = 'أدوات';
  static const String fabric = 'قماش';
  static const String threads = 'خيوط';
  static const String maintenance = 'صيانة';
  static const String transport = 'نقل';
  static const String other = 'أخرى';

  static const List<String> all = [
    rent,
    electricity,
    water,
    tools,
    fabric,
    threads,
    maintenance,
    transport,
    other,
  ];
}

/// مصروف عام على المحل
class Expense {
  final int? id;
  final String refNo;
  final DateTime date;
  final double amount;
  final String category;
  final String? description;
  final String? notes;
  final String? attachmentPath;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.refNo,
    required this.date,
    required this.amount,
    required this.category,
    this.description,
    this.notes,
    this.attachmentPath,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'ref_no': refNo,
        'date': date.millisecondsSinceEpoch,
        'amount': amount,
        'category': category,
        'description': description,
        'notes': notes,
        'attachment_path': attachmentPath,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        refNo: (m['ref_no'] as String?) ?? '',
        date: DateTime.fromMillisecondsSinceEpoch((m['date'] as int?) ?? 0),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        category: (m['category'] as String?) ?? ExpenseCategory.other,
        description: m['description'] as String?,
        notes: m['notes'] as String?,
        attachmentPath: m['attachment_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );

  Expense copyWith({
    int? id,
    String? refNo,
    DateTime? date,
    double? amount,
    String? category,
    String? description,
    String? notes,
    String? attachmentPath,
    DateTime? createdAt,
  }) =>
      Expense(
        id: id ?? this.id,
        refNo: refNo ?? this.refNo,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        attachmentPath: attachmentPath ?? this.attachmentPath,
        createdAt: createdAt ?? this.createdAt,
      );
}
