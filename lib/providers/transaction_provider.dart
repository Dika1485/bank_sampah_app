import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:bank_sampah_app/models/sampah.dart'; // Import SampahType
import 'package:bank_sampah_app/models/withdrawal_request.dart'; // Import WithdrawalRequest

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Transaction> _nasabahTransactions = [];
  List<Transaction> _pendingPengepulValidations =
      []; // Setoran yang menunggu divalidasi
  List<WithdrawalRequest> _pendingWithdrawalRequests =
      []; // Permintaan pencairan yang menunggu
  double _nasabahBalance =
      0.0; // Ini akan dibaca dari AuthProvider atau langsung dari user doc
  bool _isLoading = false;
  String? _errorMessage;

  List<Transaction> get nasabahTransactions => _nasabahTransactions;
  List<Transaction> get pendingPengepulValidations =>
      _pendingPengepulValidations;
  List<WithdrawalRequest> get pendingWithdrawalRequests =>
      _pendingWithdrawalRequests; // Getter baru
  double get nasabahBalance => _nasabahBalance; // Getter untuk saldo nasabah
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stream subscriptions
  StreamSubscription? _nasabahTransactionSubscription;
  StreamSubscription? _pendingPengepulValidationSubscription;
  StreamSubscription? _pendingWithdrawalRequestSubscription;
  StreamSubscription? _nasabahBalanceSubscription;

  TransactionProvider() {
    // Listener akan diinisialisasi ketika fungsi listenTo... dipanggil
  }

  @override
  void dispose() {
    _nasabahTransactionSubscription?.cancel();
    _pendingPengepulValidationSubscription?.cancel();
    _pendingWithdrawalRequestSubscription?.cancel();
    _nasabahBalanceSubscription?.cancel();
    super.dispose();
  }

  // Stream untuk mendengarkan perubahan transaksi nasabah dan saldo
  void listenToNasabahData(String userId) {
    // Listener untuk transaksi nasabah
    _nasabahTransactionSubscription?.cancel();
    _nasabahTransactionSubscription = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _nasabahTransactions = snapshot.docs
                .map((doc) => Transaction.fromFirestore(doc.data(), doc.id))
                .toList();
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal mendengarkan transaksi nasabah: $error';
            notifyListeners();
          },
        );

    // Listener untuk saldo nasabah (langsung dari dokumen user)
    _nasabahBalanceSubscription?.cancel();
    _nasabahBalanceSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              _nasabahBalance =
                  (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
            } else {
              _nasabahBalance = 0.0; // Jika dokumen user tidak ada, saldo 0
            }
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal mendengarkan saldo nasabah: $error';
            notifyListeners();
          },
        );
  }

  // Stream untuk mendengarkan setoran pending untuk pengepul
  void listenToPendingPengepulValidations() {
    _pendingPengepulValidationSubscription?.cancel();
    _pendingPengepulValidationSubscription = _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'setoran')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _pendingPengepulValidations = snapshot.docs
                .map((doc) => Transaction.fromFirestore(doc.data(), doc.id))
                .toList();
            notifyListeners();
          },
          onError: (error) {
            _errorMessage =
                'Gagal mendengarkan validasi setoran pending: $error';
            notifyListeners();
          },
        );
  }

  // --- Stream Baru: Untuk mendengarkan permintaan pencairan yang pending ---
  void listenToPendingWithdrawalRequests() {
    _pendingWithdrawalRequestSubscription?.cancel();
    _pendingWithdrawalRequestSubscription = _firestore
        .collection(
          'withdrawal_requests',
        ) // Koleksi baru untuk permintaan pencairan
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _pendingWithdrawalRequests = snapshot.docs
                .map(
                  (doc) => WithdrawalRequest.fromFirestore(doc.data()!, doc.id),
                )
                .toList();
            notifyListeners();
          },
          onError: (error) {
            _errorMessage =
                'Gagal mendengarkan permintaan pencairan pending: $error';
            notifyListeners();
          },
        );
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
    } on FirebaseException catch (e) {
      _errorMessage = 'Terjadi kesalahan Firestore: ${e.message}';
    } catch (e) {
      _errorMessage = 'Gagal mengajukan setoran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Metode requestPencairan yang diperbarui (Nasabah) ---
  Future<void> requestPencairan({
    required String userId,
    required String userName, // Tambahkan userName
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

    try {
      // Periksa saldo aktual nasabah dari Firestore (lebih aman)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentBalance =
          (userDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      if (amount > currentBalance) {
        _errorMessage =
            'Saldo tidak mencukupi untuk pencairan ini. Saldo Anda: Rp ${currentBalance.toStringAsFixed(0)}';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Buat permintaan pencairan baru di koleksi 'withdrawal_requests'
      // ID permintaan pencairan juga bisa digunakan sebagai referensi untuk transaksi pencairan
      final withdrawalRequestId = _firestore
          .collection('withdrawal_requests')
          .doc()
          .id;

      final newRequest = WithdrawalRequest(
        id: withdrawalRequestId, // Gunakan ID yang di-generate
        userId: userId,
        userName: userName,
        amount: amount,
        timestamp: DateTime.now(),
        status: 'pending', // Status menunggu validasi pengepul
      );

      await _firestore
          .collection('withdrawal_requests')
          .doc(newRequest.id)
          .set(newRequest.toFirestore());

      // Juga buat entri transaksi dengan status "pending" di koleksi 'transactions'
      // Ini penting agar nasabah bisa melihat status "pending" di riwayat mereka
      await _firestore
          .collection('transactions')
          .doc(withdrawalRequestId)
          .set(
            Transaction(
              id: withdrawalRequestId, // Menggunakan ID yang sama dengan request
              userId: userId,
              type: TransactionType.pencairan,
              sampahTypeId: '', // Tidak relevan untuk pencairan
              sampahTypeName: 'Permintaan Pencairan Dana', // Nama deskriptif
              weightKg: 0.0, // Tidak relevan
              amount: amount,
              timestamp: DateTime.now(),
              status: TransactionStatus.pending, // Status awal adalah pending
            ).toFirestore(),
          );
      _errorMessage = null;
    } on FirebaseException catch (e) {
      _errorMessage = 'Terjadi kesalahan Firestore: ${e.message}';
    } catch (e) {
      _errorMessage = 'Gagal mengajukan pencairan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> validateSetoran({
    required String transactionId,
    required String pengepulId,
    required double actualWeightKg,
    required SampahType sampahType,
    required String userId, // Perlu userId nasabah untuk update saldo
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.runTransaction((transaction) async {
        final transactionRef = _firestore
            .collection('transactions')
            .doc(transactionId);
        final userRef = _firestore.collection('users').doc(userId);

        final transactionDoc = await transaction.get(transactionRef);
        final userDoc = await transaction.get(userRef);

        if (!transactionDoc.exists || !userDoc.exists) {
          throw Exception('Transaksi atau pengguna tidak ditemukan.');
        }

        final currentTransaction = Transaction.fromFirestore(
          transactionDoc.data()!,
          transactionDoc.id,
        );

        if (currentTransaction.status != TransactionStatus.pending) {
          throw Exception('Transaksi ini sudah divalidasi atau dibatalkan.');
        }

        final earnedAmount = actualWeightKg * sampahType.pricePerKg;
        final currentBalance =
            (userDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;

        // 1. Update transaksi setoran
        transaction.update(transactionRef, {
          'weightKg': actualWeightKg,
          'amount': earnedAmount,
          'status': 'completed', // Pastikan menggunakan string 'completed'
          'pengepulId': pengepulId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. Update saldo nasabah
        transaction.update(userRef, {'balance': currentBalance + earnedAmount});
      });

      _errorMessage = null;
    } on FirebaseException catch (e) {
      _errorMessage = 'Terjadi kesalahan Firestore: ${e.message}';
    } catch (e) {
      _errorMessage = 'Gagal memvalidasi setoran: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> processWithdrawalRequest(
    WithdrawalRequest request,
    String pengepulId,
    bool approve,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.runTransaction((transaction) async {
        final userDocRef = _firestore.collection('users').doc(request.userId);
        final withdrawalRequestDocRef = _firestore
            .collection('withdrawal_requests')
            .doc(request.id);
        // Ambil juga referensi ke transaksi di koleksi 'transactions' yang terkait
        final relatedTransactionRef = _firestore
            .collection('transactions')
            .doc(request.id);

        final userSnapshot = await transaction.get(userDocRef);
        final withdrawalRequestSnapshot = await transaction.get(
          withdrawalRequestDocRef,
        );
        final relatedTransactionSnapshot = await transaction.get(
          relatedTransactionRef,
        );

        if (!userSnapshot.exists) {
          throw Exception('User not found!');
        }
        if (!withdrawalRequestSnapshot.exists) {
          throw Exception('Permintaan pencairan tidak ditemukan!');
        }
        if (!relatedTransactionSnapshot.exists) {
          // Ini bisa terjadi jika nasabah mengajukan pencairan tapi entri di 'transactions' belum terbuat karena suatu error.
          // Namun, dengan kode requestPencairan yang diperbarui, ini seharusnya tidak terjadi.
          // Kita bisa memilih untuk melemparkan error atau membuatnya. Untuk saat ini, kita anggap itu harus ada.
          throw Exception('Transaksi terkait tidak ditemukan di riwayat!');
        }

        final currentBalance =
            (userSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        final currentRequestStatus =
            withdrawalRequestSnapshot.data()?['status'] as String? ?? 'unknown';

        if (currentRequestStatus != 'pending') {
          throw Exception('Permintaan pencairan ini sudah diproses.');
        }

        if (approve) {
          if (currentBalance < request.amount) {
            throw Exception(
              'Saldo nasabah tidak mencukupi untuk pencairan ini.',
            );
          }
          // Kurangi saldo nasabah
          transaction.update(userDocRef, {
            'balance': currentBalance - request.amount,
          });
          // Update status permintaan pencairan
          transaction.update(withdrawalRequestDocRef, {
            'status': 'completed',
            'validatedByPengepulId': pengepulId,
            'validationTimestamp': FieldValue.serverTimestamp(),
          });

          // Update status transaksi di koleksi 'transactions' menjadi completed
          transaction.update(relatedTransactionRef, {
            'status': 'completed',
            'pengepulId': pengepulId,
            'timestamp':
                FieldValue.serverTimestamp(), // Update timestamp untuk waktu penyelesaian
          });
        } else {
          // Jika ditolak, hanya update status permintaan
          transaction.update(withdrawalRequestDocRef, {
            'status': 'rejected',
            'validatedByPengepulId': pengepulId,
            'validationTimestamp': FieldValue.serverTimestamp(),
          });

          // Update status transaksi di koleksi 'transactions' menjadi rejected
          transaction.update(relatedTransactionRef, {
            'status': 'rejected',
            'pengepulId': pengepulId, // Tetap simpan pengepul yang menolak
            'timestamp':
                FieldValue.serverTimestamp(), // Update timestamp untuk waktu penolakan
          });
        }
      });
    } on FirebaseException catch (e) {
      _errorMessage = 'Terjadi kesalahan Firestore: ${e.message}';
    } catch (e) {
      _errorMessage = 'Gagal memproses pencairan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
