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
        _loadAppUser(user.uid);
      } else {
        _appUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data pengguna: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nama,
    required String nik,
    required String noKtp, // Ini akan menjadi URL setelah upload
    required UserType userType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      // Simpan data user tambahan di Firestore
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'nama': nama,
        'nik': nik,
        'noKtp':
            noKtp, // Asumsi ini sudah URL gambar KTP yang diupload ke Firebase Storage
        'userType': userType == UserType.nasabah ? 'nasabah' : 'pengepul',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadAppUser(uid); // Muat data AppUser setelah registrasi
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
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
      default:
        return 'Gagal autentikasi. Silakan coba lagi.';
    }
  }
}
