import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        // Ketika auth state berubah, muat ulang AppUser
        _loadAppUser(user.uid);
      } else {
        _appUser = null;
        notifyListeners(); // Beri tahu listener bahwa user sudah logout
      }
    });
  }

  // Metode ini sekarang mengembalikan AppUser setelah dimuat
  Future<AppUser?> _loadAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc.data()!, doc.id);
        notifyListeners(); // Beri tahu listener setelah _appUser diatur
        return _appUser;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data pengguna: $e';
      notifyListeners();
    }
    return null;
  }

  // Mengembalikan AppUser? untuk memudahkan penanganan di UI
  Future<AppUser?> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppUser? loggedInUser;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        loggedInUser = await _loadAppUser(
          userCredential.user!.uid,
        ); // Pastikan AppUser dimuat sebelum kembali
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Update UI dengan status loading dan error terbaru
    }
    return loggedInUser;
  }

  // Mengembalikan AppUser? untuk memudahkan penanganan di UI
  Future<AppUser?> register({
    required String email,
    required String password,
    required String nama,
    required String nik,
    required UserType userType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppUser? registeredUser;
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'nama': nama,
        'nik': nik,
        'userType': userType == UserType.nasabah ? 'nasabah' : 'pengepul',
        'createdAt': FieldValue.serverTimestamp(),
        'balance': 0.0, // Inisialisasi saldo untuk nasabah baru jika perlu
      });

      registeredUser = await _loadAppUser(
        uid,
      ); // Pastikan AppUser dimuat setelah register
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return registeredUser;
  }

  Future<List<AppUser>> fetchPengepulUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'pengepul')
          .get();
      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data()!, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching pengepul users: $e');
      return [];
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signOut();
      _appUser = null; // Pastikan _appUser direset saat logout
      _firebaseUser = null; // Pastikan _firebaseUser direset saat logout
    } catch (e) {
      _errorMessage = 'Gagal logout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Email sudah digunakan.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Coba lagi.';
      default:
        return 'Gagal autentikasi. Silakan coba lagi.';
    }
  }
}
