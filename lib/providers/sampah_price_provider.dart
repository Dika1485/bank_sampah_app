import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/sampah.dart';
import 'dart:async'; // Import untuk StreamSubscription

class SampahPriceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SampahType> _sampahTypes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SampahType> get sampahTypes => _sampahTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _sampahTypesSubscription;

  SampahPriceProvider() {
    _listenToSampahTypes();
  }

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

  SampahType? getSampahTypeById(String id) {
    try {
      return _sampahTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      // Jika tidak ditemukan, firstWhere akan melempar StateError.
      return null;
    }
  }
  // ----------------------------------------------------------------

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

  Future<void> deleteSampahType(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.collection('sampah_types').doc(id).delete();
      _errorMessage = null; // Clear any previous error message on success
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menghapus jenis sampah: ${e.message}';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners even on error to update UI state
    }
  }

  @override
  void dispose() {
    _sampahTypesSubscription?.cancel();
    super.dispose();
  }
}
