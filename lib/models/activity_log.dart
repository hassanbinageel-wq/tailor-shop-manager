/// سجل نشاط لكل عملية تتم في التطبيق
class ActivityLog {
  final int? id;
  final String action; // إضافة / تعديل / حذف / استعادة ...
  final String entity; // خياط / مصروف / حركة ...
  final int? entityId;
  final String description;
  final DateTime timestamp;

  const ActivityLog({
    this.id,
    required this.action,
    required this.entity,
    this.entityId,
    required this.description,
    required this.timestamp,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'action': action,
        'entity': entity,
        'entity_id': entityId,
        'description': description,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ActivityLog.fromMap(Map<String, Object?> m) => ActivityLog(
        id: m['id'] as int?,
        action: (m['action'] as String?) ?? '',
        entity: (m['entity'] as String?) ?? '',
        entityId: m['entity_id'] as int?,
        description: (m['description'] as String?) ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch((m['timestamp'] as int?) ?? 0),
      );
}
