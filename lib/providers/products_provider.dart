import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/product.dart';

class ProductsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _productsSubscription;

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  void listenToProducts() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _productsSubscription?.cancel();
    _productsSubscription = _firestore
        .collection('products')
        .snapshots()
        .listen(
          (snapshot) {
            final List<Product> loadedProducts = [];
            for (final doc in snapshot.docs) {
              try {
                // Gunakan try-catch di sini untuk setiap dokumen
                loadedProducts.add(Product.fromFirestore(doc));
              } catch (e) {
                // Cetak error untuk debugging, tapi jangan hentikan aplikasi
                print('Error memuat produk dengan ID ${doc.id}: $e');
              }
            }
            _products = loadedProducts;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = 'Gagal memuat produk: $error';
            notifyListeners();
          },
        );
  }

  Future<void> addProduct(Product newProduct) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _firestore.collection('products').add(newProduct.toFirestore());
      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menambahkan produk: ${e.message}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editProduct(Product updatedProduct) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _firestore
          .collection('products')
          .doc(updatedProduct.id)
          .update(updatedProduct.toFirestore());
      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal mengedit produk: ${e.message}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _firestore.collection('products').doc(id).delete();
      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menghapus produk: ${e.message}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
