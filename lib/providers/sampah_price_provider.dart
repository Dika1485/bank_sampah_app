import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/sampah.dart';

class SampahPriceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<SampahType> _sampahTypes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SampahType> get sampahTypes => _sampahTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SampahPriceProvider() {
    _loadSampahPrices(); // Muat harga saat provider dibuat
  }

  Future<void> _loadSampahPrices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('sampah_prices').get();
      _sampahTypes = snapshot.docs
          .map((doc) => SampahType.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat harga sampah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk pengepul mengupdate harga
  Future<void> updateSampahPrice(String sampahTypeId, double newPrice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.collection('sampah_prices').doc(sampahTypeId).update({
        'pricePerKg': newPrice,
      });
      await _loadSampahPrices(); // Refresh data
      _errorMessage = null; // Clear error on success
    } catch (e) {
      _errorMessage = 'Gagal memperbarui harga sampah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk pengepul menambahkan jenis sampah baru
  Future<void> addSampahType({
    required String name,
    required SampahCategory category,
    required double pricePerKg,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.collection('sampah_prices').add({
        'name': name,
        'category': category == SampahCategory.organik
            ? 'organik'
            : 'anorganik',
        'pricePerKg': pricePerKg,
      });
      await _loadSampahPrices(); // Refresh data
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal menambah jenis sampah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper untuk mendapatkan harga berdasarkan ID
  SampahType? getSampahTypeById(String id) {
    try {
      return _sampahTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }
}
