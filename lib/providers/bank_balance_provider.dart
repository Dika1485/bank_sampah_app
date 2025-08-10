import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BankBalanceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _totalRevenue = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  double get totalRevenue => _totalRevenue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BankBalanceProvider() {
    _listenToTotalRevenue();
  }

  // Menghapus metode addBalance karena tugas ini sudah ditangani oleh TransactionProvider.
  // Jika Anda ingin menambah atau mengurangi saldo, panggil metode di TransactionProvider.

  void _listenToTotalRevenue() {
    _isLoading = true;
    _firestore
        .collection('bank_data') // Menggunakan nama koleksi yang konsisten
        .doc('balance') // Menggunakan nama dokumen yang konsisten
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              _totalRevenue =
                  (snapshot.data()?['totalRevenue'] as num?)?.toDouble() ?? 0.0;
            } else {
              _totalRevenue = 0.0;
            }
            _isLoading = false;
            _errorMessage = null; // Menghapus pesan error jika berhasil
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat saldo bank: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }
}
