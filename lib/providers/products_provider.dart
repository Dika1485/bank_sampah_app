import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/product.dart';
// 💡 Import CloudinaryService
import 'package:bank_sampah_app/services/cloudinary_service.dart';

class ProductsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 💡 Inisialisasi CloudinaryService
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // ❌ HAPUS KREDENSIAL CLOUDINARY DARI SINI
  // static const String CLOUDINARY_CLOUD_NAME = 'dzjrfadjn';
  // static const String CLOUDINARY_UPLOAD_PRESET = 'flutter_upload';

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

  // -------------------------------------------------------------------
  // READ (LISTEN)
  // -------------------------------------------------------------------

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
                loadedProducts.add(Product.fromFirestore(doc));
              } catch (e) {
                // Pastikan Product.fromFirestore(doc) sudah benar
                debugPrint('Error memuat produk dengan ID ${doc.id}: $e');
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

  // -------------------------------------------------------------------
  // IMAGE UPLOAD (MENGGUNAKAN CLOUDINARY SERVICE)
  // -------------------------------------------------------------------

  /// 💡 Ganti fungsi lama dengan panggilang ke CloudinaryService.
  /// Fungsi ini digunakan oleh UI sebelum memanggil add/editProduct.
  Future<String?> uploadImageAndGetUrl(File imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Panggil metode upload khusus produk dari service
      final imageUrl = await _cloudinaryService.uploadProductImage(imageFile);

      _isLoading = false;
      notifyListeners();
      return imageUrl;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal mengunggah gambar: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // -------------------------------------------------------------------
  // CREATE & UPDATE
  // -------------------------------------------------------------------

  Future<void> addProduct(Product newProduct) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Pastikan newProduct sudah memiliki imageUrl (hasil dari uploadImageAndGetUrl)
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

      // updatedProduct.toFirestore() harus mencakup field 'imageUrl' baru/lama
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

  // -------------------------------------------------------------------
  // DELETE
  // -------------------------------------------------------------------

  Future<void> deleteProduct(Product productToDelete) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 💡 Opsional: Hapus gambar dari Cloudinary sebelum menghapus data Firestore
      if (productToDelete.imageUrl != null &&
          productToDelete.imageUrl!.isNotEmpty) {
        // Panggil metode delete dari service
        await _cloudinaryService.deleteImageByUrl(productToDelete.imageUrl!);
        // Ingat: Metode ini hanya berhasil jika Anda menggunakan solusi backend yang aman
      }

      await _firestore.collection('products').doc(productToDelete.id).delete();

      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menghapus produk: ${e.message}';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghapus gambar atau produk: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
