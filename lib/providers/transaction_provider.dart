import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:bank_sampah_app/models/sampah.dart'; // Import SampahType
import 'package:bank_sampah_app/models/withdrawal_request.dart'; // Import WithdrawalRequest

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Transaction> _nasabahTransactions = [];
  List<Transaction> _pendingPengepulValidations = [];
  List<WithdrawalRequest> _pendingWithdrawalRequests = [];
  double _nasabahBalance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  List<Transaction> get nasabahTransactions => _nasabahTransactions;
  List<Transaction> get pendingPengepulValidations =>
      _pendingPengepulValidations;
  List<WithdrawalRequest> get pendingWithdrawalRequests =>
      _pendingWithdrawalRequests;
  double get nasabahBalance => _nasabahBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _nasabahTransactionSubscription;
  StreamSubscription? _pendingPengepulValidationSubscription;
  StreamSubscription? _pendingWithdrawalRequestSubscription;
  StreamSubscription? _nasabahBalanceSubscription;

  TransactionProvider();

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
              _nasabahBalance = 0.0;
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

  // Stream untuk mendengarkan permintaan pencairan yang pending (untuk semua pengepul)
  void listenToPendingWithdrawalRequests() {
    _pendingWithdrawalRequestSubscription?.cancel();
    _pendingWithdrawalRequestSubscription = _firestore
        .collection('withdrawal_requests')
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
              id: '',
              userId: userId,
              type: TransactionType.setoran,
              sampahTypeId: sampahType.id,
              sampahTypeName: sampahType.name,
              weightKg: estimatedWeightKg,
              amount: 0.0,
              timestamp: DateTime.now(),
              status: TransactionStatus.pending,
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

  Future<void> requestPencairan({
    required String userId,
    required String userName,
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

      final withdrawalRequestId = _firestore
          .collection('withdrawal_requests')
          .doc()
          .id;

      final newRequest = WithdrawalRequest(
        id: withdrawalRequestId,
        userId: userId,
        userName: userName,
        amount: amount,
        timestamp: DateTime.now(),
        status: 'pending',
      );

      await _firestore
          .collection('withdrawal_requests')
          .doc(newRequest.id)
          .set(newRequest.toFirestore());

      await _firestore
          .collection('transactions')
          .doc(withdrawalRequestId)
          .set(
            Transaction(
              id: withdrawalRequestId,
              userId: userId,
              type: TransactionType.pencairan,
              sampahTypeId: '',
              sampahTypeName: 'Permintaan Pencairan Dana',
              weightKg: 0.0,
              amount: amount,
              timestamp: DateTime.now(),
              status: TransactionStatus.pending,
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

  // MARK: - Fungsi Pengepul
  Future<void> validateSetoran({
    required String transactionId,
    required String pengepulId,
    required double actualWeightKg,
    required SampahType sampahType,
    required String userId,
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

        transaction.update(transactionRef, {
          'weightKg': actualWeightKg,
          'amount': earnedAmount,
          'status': 'completed',
          'pengepulId': pengepulId,
          'timestamp': FieldValue.serverTimestamp(),
        });

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

  // Fungsi pencairan yang Divalidasi oleh Pengepul
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
          throw Exception('User tidak ditemukan!');
        }
        if (!withdrawalRequestSnapshot.exists) {
          throw Exception('Permintaan pencairan tidak ditemukan!');
        }
        if (!relatedTransactionSnapshot.exists) {
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
          transaction.update(userDocRef, {
            'balance': currentBalance - request.amount,
          });
          transaction.update(withdrawalRequestDocRef, {
            'status': 'completed',
            'validatedByPengepulId': pengepulId,
            'validationTimestamp': FieldValue.serverTimestamp(),
          });

          transaction.update(relatedTransactionRef, {
            'status': 'completed',
            'pengepulId': pengepulId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(withdrawalRequestDocRef, {
            'status': 'rejected',
            'validatedByPengepulId': pengepulId,
            'validationTimestamp': FieldValue.serverTimestamp(),
          });

          transaction.update(relatedTransactionRef, {
            'status': 'rejected',
            'pengepulId': pengepulId,
            'timestamp': FieldValue.serverTimestamp(),
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
