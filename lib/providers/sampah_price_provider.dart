import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/sampah.dart';
import 'package:bank_sampah_app/models/product.dart'; // Import jika ada model produk

class SampahPriceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SampahType> _sampahTypes = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _sampahTypesSubscription;

  List<SampahType> get sampahTypes => _sampahTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SampahPriceProvider() {
    _listenToSampahTypes();
  }

  // Hapus semua kode terkait stok sampah dari provider ini.
  // Stok sampah sekarang menjadi tanggung jawab TransactionProvider.
  // Hapus properti:
  // Map<String, double> _currentStock = {};
  // StreamSubscription? _wasteStockSubscription;
  // Hapus getter:
  // Map<String, double> get currentStock => _currentStock;
  // Hapus fungsi:
  // void _listenToWasteStock() { ... }
  // Future<void> reduceWasteStock(Map<String, double> soldWaste) async { ... }

  void _listenToSampahTypes() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _sampahTypesSubscription?.cancel();
    _sampahTypesSubscription = _firestore
        .collection('sampah_types')
        .orderBy('name')
        .snapshots()
        .listen(
          (snapshot) {
            _sampahTypes = snapshot.docs
                .map((doc) => SampahType.fromFirestore(doc.data(), doc.id))
                .toList();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = 'Gagal memuat jenis sampah: $error';
            notifyListeners();
            print('Error fetching sampah types: $error');
          },
        );
  }

  // Fungsi untuk mendapatkan data jenis sampah berdasarkan ID
  SampahType? getSampahTypeById(String id) {
    try {
      return _sampahTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk menambah jenis sampah baru (tidak ada perubahan)
  Future<void> addSampahType({
    required String name,
    required SampahCategory category,
    required double pricePerKg,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final existingDocs = await _firestore
          .collection('sampah_types')
          .where('name', isEqualTo: name.trim())
          .limit(1)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        throw 'Jenis sampah dengan nama "$name" sudah ada.';
      }

      await _firestore.collection('sampah_types').add({
        'name': name.trim(),
        'category': category.toString().split('.').last,
        'pricePerKg': pricePerKg,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _errorMessage = null;
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menambahkan jenis sampah: ${e.message}';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk mengubah harga sampah (tidak ada perubahan)
  Future<void> updateSampahPrice(String id, double newPrice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.collection('sampah_types').doc(id).update({
        'pricePerKg': newPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _errorMessage = null;
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal memperbarui harga sampah: ${e.message}';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk menghapus jenis sampah (tidak ada perubahan)
  Future<void> deleteSampahType(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.collection('sampah_types').doc(id).delete();
      _errorMessage = null;
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menghapus jenis sampah: ${e.message}';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sampahTypesSubscription?.cancel();
    super.dispose();
  }
}
