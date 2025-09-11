import 'package:cloud_firestore/cloud_firestore.dart';

// Tipe transaksi yang diperluas
enum TransactionType { setoran, pencairan, jualsampah, produk }

// Status validasi transaksi
enum TransactionStatus { pending, completed, rejected }

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

  // Factory constructor untuk membuat objek Transaction dari Firestore
  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      userId: data['userId'] ?? '',
      pengepulId: data['pengepulId'],
      type: _mapTypeFromString(data['type']), // Menggunakan helper function
      sampahTypeId: data['sampahTypeId'] ?? '',
      sampahTypeName: data['sampahTypeName'] ?? '',
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0.0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: _mapStatusFromString(data['status']),
    );
  }

  // Method untuk mengubah objek Transaction menjadi format yang bisa disimpan di Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pengepulId': pengepulId,
      'type': type
          .toString()
          .split('.')
          .last, // 'setoran', 'pencairan', 'jualsampah', 'produk'
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

  // Helper function untuk memetakan string status menjadi enum
  static TransactionStatus _mapStatusFromString(String statusString) {
    switch (statusString) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'rejected':
        return TransactionStatus.rejected;
      default:
        return TransactionStatus.pending;
    }
  }

  // Helper function baru untuk memetakan string tipe transaksi menjadi enum
  static TransactionType _mapTypeFromString(String typeString) {
    switch (typeString) {
      case 'setoran':
        return TransactionType.setoran;
      case 'pencairan':
        return TransactionType.pencairan;
      case 'jualsampah':
        return TransactionType.jualsampah;
      case 'produk':
        return TransactionType.produk;
      default:
        return TransactionType.setoran;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
