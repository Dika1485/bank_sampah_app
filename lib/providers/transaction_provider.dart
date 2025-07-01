import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:bank_sampah_app/models/sampah.dart'; // Import SampahType

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Transaction> _nasabahTransactions = [];
  List<Transaction> _pendingPengepulValidations =
      []; // Setoran yang menunggu divalidasi
  double _nasabahBalance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  List<Transaction> get nasabahTransactions => _nasabahTransactions;
  List<Transaction> get pendingPengepulValidations =>
      _pendingPengepulValidations;
  double get nasabahBalance => _nasabahBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stream untuk mendengarkan perubahan transaksi nasabah dan saldo
  void listenToNasabahTransactions(String userId) {
    _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          _nasabahTransactions = snapshot.docs
              .map((doc) => Transaction.fromFirestore(doc.data(), doc.id))
              .toList();
          _calculateNasabahBalance(); // Hitung ulang saldo setiap ada perubahan
          notifyListeners();
        });
  }

  // Stream untuk mendengarkan setoran pending untuk pengepul
  void listenToPendingPengepulValidations() {
    _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'setoran')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          _pendingPengepulValidations = snapshot.docs
              .map((doc) => Transaction.fromFirestore(doc.data(), doc.id))
              .toList();
          notifyListeners();
        });
  }

  void _calculateNasabahBalance() {
    double totalSetoran = _nasabahTransactions
        .where(
          (t) =>
              t.type == TransactionType.setoran &&
              t.status == TransactionStatus.completed,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    double totalPencairan = _nasabahTransactions
        .where(
          (t) =>
              t.type == TransactionType.pencairan &&
              t.status == TransactionStatus.completed,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    _nasabahBalance = totalSetoran - totalPencairan;
  }

  // MARK: - Fungsi Nasabah
  Future<void> requestSetoran({
    required String userId,
    required SampahType sampahType,
    required double estimatedWeightKg,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore
          .collection('transactions')
          .add(
            Transaction(
              id: '', // ID akan di-generate Firestore
              userId: userId,
              type: TransactionType.setoran,
              sampahTypeId: sampahType.id,
              sampahTypeName: sampahType.name,
              weightKg: estimatedWeightKg,
              amount: 0.0, // Amount awal 0, akan diisi oleh pengepul
              timestamp: DateTime.now(),
              status: TransactionStatus.pending, // Status menunggu validasi
            ).toFirestore(),
          );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal mengajukan setoran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPencairan({
    required String userId,
    required String pengepulId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (amount <= 0) {
      _errorMessage = 'Jumlah pencairan harus lebih dari 0.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (amount > _nasabahBalance) {
      _errorMessage = 'Saldo tidak mencukupi untuk pencairan ini.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await _firestore
          .collection('transactions')
          .add(
            Transaction(
              id: '',
              userId: userId,
              pengepulId: pengepulId, // Pengepul yang memproses pencairan
              type: TransactionType.pencairan,
              sampahTypeId: '', // Tidak relevan untuk pencairan
              sampahTypeName: 'Pencairan Dana',
              weightKg: 0.0, // Tidak relevan
              amount: amount,
              timestamp: DateTime.now(),
              status: TransactionStatus
                  .completed, // Pencairan dianggap selesai langsung
            ).toFirestore(),
          );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal mengajukan pencairan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MARK: - Fungsi Pengepul
  Future<void> validateSetoran({
    required String transactionId,
    required String pengepulId,
    required double actualWeightKg,
    required SampahType sampahType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final transactionRef = _firestore
          .collection('transactions')
          .doc(transactionId);
      final transactionDoc = await transactionRef.get();
      if (!transactionDoc.exists) {
        _errorMessage = 'Transaksi tidak ditemukan.';
        return;
      }

      final currentTransaction = Transaction.fromFirestore(
        transactionDoc.data()!,
        transactionDoc.id,
      );

      // Pastikan hanya transaksi pending yang bisa divalidasi
      if (currentTransaction.status != TransactionStatus.pending) {
        _errorMessage = 'Transaksi ini sudah divalidasi atau dibatalkan.';
        return;
      }

      final earnedAmount = actualWeightKg * sampahType.pricePerKg;

      await transactionRef.update({
        'weightKg': actualWeightKg,
        'amount': earnedAmount,
        'status': 'completed',
        'pengepulId': pengepulId, // Simpan ID pengepul yang memvalidasi
        'timestamp': FieldValue.serverTimestamp(), // Update timestamp validasi
      });

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memvalidasi setoran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
