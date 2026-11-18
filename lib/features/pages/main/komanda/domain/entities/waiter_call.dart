enum WaiterCallType { call, message, urgent }
enum WaiterCallStatus { pending, done }
extension WaiterCallStatusX on WaiterCallStatus { String get label => this == WaiterCallStatus.pending ? 'Pendiente' : 'Atendido'; }

class WaiterCall {
  final String id;
  final String table;
  final String message;
  final WaiterCallType type;
  final WaiterCallStatus status;
  final DateTime createdAt;
  final String waiterId;
  final String waiterName;

  const WaiterCall({required this.id, required this.table, required this.message, required this.type, required this.status, required this.createdAt, this.waiterId = '', this.waiterName = ''});
  WaiterCall copyWith({String? id, String? table, String? message, WaiterCallType? type, WaiterCallStatus? status, DateTime? createdAt, String? waiterId, String? waiterName}) => WaiterCall(
    id: id ?? this.id, table: table ?? this.table, message: message ?? this.message,
    type: type ?? this.type, status: status ?? this.status, createdAt: createdAt ?? this.createdAt,
    waiterId: waiterId ?? this.waiterId, waiterName: waiterName ?? this.waiterName,
  );
}
