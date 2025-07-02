import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequest {
  final String id;
  final String userId; // ID Nasabah yang melakukan pencairan
  final String userName; // Nama Nasabah (untuk tampilan mudah)
  final double amount; // Jumlah dana yang ingin dicairkan
  final DateTime timestamp; // Waktu permintaan dibuat
  String status; // 'pending', 'completed', 'rejected'
  final String? validatedByPengepulId; // ID Pengepul yang memvalidasi
  final DateTime? validationTimestamp; // Waktu validasi

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.timestamp,
    this.status = 'pending',
    this.validatedByPengepulId,
    this.validationTimestamp,
  });

  // Factory constructor untuk membuat objek WithdrawalRequest dari Firestore Document
  factory WithdrawalRequest.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return WithdrawalRequest(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      validatedByPengepulId: data['validatedByPengepulId'],
      validationTimestamp: (data['validationTimestamp'] as Timestamp?)
          ?.toDate(),
    );
  }

  // Metode untuk mengonversi objek WithdrawalRequest ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'validatedByPengepulId': validatedByPengepulId,
      'validationTimestamp': validationTimestamp != null
          ? Timestamp.fromDate(validationTimestamp!)
          : null,
    };
  }
}
