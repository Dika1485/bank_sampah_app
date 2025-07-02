import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { setoran, pencairan }

enum TransactionStatus {
  pending,
  completed,
  rejected,
} // Untuk setoran yang perlu divalidasi

class Transaction {
  final String id;
  final String userId; // ID Nasabah
  final String? pengepulId; // ID Pengepul yang memvalidasi/mencairkan
  final TransactionType type;
  final String sampahTypeId; // ID jenis sampah (jika setoran)
  final String sampahTypeName; // Nama jenis sampah (untuk tampilan)
  final double weightKg; // Berat dalam kg (untuk setoran)
  final double amount; // Nominal uang (untuk setoran/pencairan)
  final DateTime timestamp;
  final TransactionStatus status; // Untuk validasi setoran

  Transaction({
    required this.id,
    required this.userId,
    this.pengepulId,
    required this.type,
    required this.sampahTypeId,
    required this.sampahTypeName,
    required this.weightKg,
    required this.amount,
    required this.timestamp,
    required this.status,
  });

  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      userId: data['userId'] ?? '',
      pengepulId: data['pengepulId'],
      type: (data['type'] == 'setoran')
          ? TransactionType.setoran
          : TransactionType.pencairan,
      sampahTypeId: data['sampahTypeId'] ?? '',
      sampahTypeName: data['sampahTypeName'] ?? '',
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0.0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: _mapStatusFromString(data['status']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pengepulId': pengepulId,
      'type': type == TransactionType.setoran ? 'setoran' : 'pencairan',
      'sampahTypeId': sampahTypeId,
      'sampahTypeName': sampahTypeName,
      'weightKg': weightKg,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status
          .toString()
          .split('.')
          .last, // 'pending', 'completed', 'rejected'
    };
  }

  static TransactionStatus _mapStatusFromString(String statusString) {
    switch (statusString) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'rejected':
        return TransactionStatus.rejected;
      default:
        return TransactionStatus.pending; // Default atau throw error
    }
  }

  @override
  bool operator ==(Object other) {
    // Dua objek Transaction dianggap sama jika ID-nya sama
    if (identical(this, other))
      return true; // Jika objeknya sama persis di memori
    return other is Transaction && // Jika 'other' adalah objek Transaction
        other.id == id; // Dan ID-nya sama
  }

  @override
  int get hashCode => id.hashCode; // Hash code harus berdasarkan ID
}
