import 'enums.dart';

/// payment_ledger table/collection.
/// Every rupee movement in BLOB is a row here. Amounts are INR paise.
class LedgerEntry {
  final String id;
  final String payerId;
  final String payerName;
  final String payeeId;
  final String payeeName;
  final int amountPaise;
  final LedgerType type;
  final PaymentStatus status;
  final String reference; // job id / listing id / booking id
  final String note;
  final DateTime createdAt;
  final DateTime? clearedAt;

  /// Payment gateway id (e.g. Razorpay `pay_xxx`) for reconciling against
  /// the gateway dashboard. Null for entries settled outside the gateway.
  final String? gatewayRef;

  const LedgerEntry({
    required this.id,
    required this.payerId,
    required this.payerName,
    required this.payeeId,
    required this.payeeName,
    required this.amountPaise,
    required this.type,
    required this.reference,
    required this.note,
    required this.createdAt,
    this.status = PaymentStatus.pending,
    this.clearedAt,
    this.gatewayRef,
  });

  LedgerEntry copyWith({PaymentStatus? status, DateTime? clearedAt}) =>
      LedgerEntry(
        id: id,
        payerId: payerId,
        payerName: payerName,
        payeeId: payeeId,
        payeeName: payeeName,
        amountPaise: amountPaise,
        type: type,
        status: status ?? this.status,
        reference: reference,
        note: note,
        createdAt: createdAt,
        clearedAt: clearedAt ?? this.clearedAt,
        gatewayRef: gatewayRef,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'payer_id': payerId,
    'payer_name': payerName,
    'payee_id': payeeId,
    'payee_name': payeeName,
    'amount_paise': amountPaise,
    'type': type.name,
    'status': status.name,
    'reference': reference,
    'note': note,
    'created_at': createdAt.toIso8601String(),
    'cleared_at': clearedAt?.toIso8601String(),
    'gateway_ref': gatewayRef,
  };

  factory LedgerEntry.fromMap(Map<dynamic, dynamic> m) => LedgerEntry(
    id: m['id'] as String? ?? '',
    payerId: m['payer_id'] as String? ?? '',
    payerName: m['payer_name'] as String? ?? '',
    payeeId: m['payee_id'] as String? ?? '',
    payeeName: m['payee_name'] as String? ?? '',
    amountPaise: (m['amount_paise'] as num?)?.toInt() ?? 0,
    type: LedgerTypeX.fromId(m['type'] as String? ?? 'laborWage'),
    status: PaymentStatusX.fromId(m['status'] as String? ?? 'pending'),
    reference: m['reference'] as String? ?? '',
    note: m['note'] as String? ?? '',
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    clearedAt: DateTime.tryParse(m['cleared_at'] as String? ?? ''),
    gatewayRef: m['gateway_ref'] as String?,
  );
}
