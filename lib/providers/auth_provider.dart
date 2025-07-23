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
  List<AppUser> _allUsers = []; // Properti untuk menyimpan daftar semua user

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AppUser> get allUsers => _allUsers; // Getter untuk semua user

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadAppUser(user.uid);
        _listenToAllUsers(); // Mulai mendengarkan semua user saat login
      } else {
        _appUser = null;
        _allUsers = []; // Kosongkan daftar user saat logout
        notifyListeners();
      }
    });

    // Inisialisasi daftar user saat aplikasi dimulai (jika sudah login sebelumnya)
    if (_auth.currentUser != null) {
      _listenToAllUsers();
    }
  }

  Future<AppUser?> _loadAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc.data()!, doc.id);
        notifyListeners();
        return _appUser;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data pengguna: $e';
      notifyListeners();
    }
    return null;
  }

  void _listenToAllUsers() {
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('users')
        .snapshots()
        .listen((snapshot) {
          _allUsers = snapshot.docs.map((doc) {
            return AppUser.fromFirestore(doc.data()!, doc.id);
          }).toList();
          _isLoading = false;
          _errorMessage = null; // Reset error on successful fetch
          notifyListeners();
        })
        .onError((error) {
          _isLoading = false;
          _errorMessage = 'Failed to load users: $error';
          debugPrint('Error loading users: $error');
          notifyListeners();
        });
  }

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
        loggedInUser = await _loadAppUser(userCredential.user!.uid);
        _listenToAllUsers(); // Mulai mendengarkan daftar user setelah login
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return loggedInUser;
  }

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

      bool initialValidationStatus = (userType == UserType.nasabah);

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'nama': nama,
        'nik': nik,
        'userType': userType.toString().split('.').last,
        'validated': initialValidationStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'saldo': 0.0,
      });

      registeredUser = await _loadAppUser(uid);
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

  Future<void> updateUserValidationStatus(
    String userId,
    bool isValidated,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(userId).update({
        'validated': isValidated,
      });

      if (_appUser != null && _appUser!.id == userId) {
        _appUser = _appUser!.copyWith(validated: isValidated);
      }
    } catch (e) {
      _errorMessage = 'Gagal memperbarui status validasi: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  // --- METHOD BARU: UPDATE DATA USER ---
  Future<void> updateUserData({
    required String userId,
    required String nama,
    required String nik,
    required UserType userType,
    required bool validated,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(userId).update({
        'nama': nama,
        'nik': nik,
        'userType': userType.toString().split('.').last,
        'validated': validated,
      });

      // Perbarui juga data user yang sedang login jika itu dirinya sendiri
      if (_appUser != null && _appUser!.id == userId) {
        _appUser = _appUser!.copyWith(
          nama: nama,
          nik: nik,
          userType: userType,
          validated: validated,
        );
      }
    } catch (e) {
      _errorMessage = 'Gagal memperbarui data pengguna: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- METHOD BARU: DELETE USER ---
  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Hapus dokumen user dari Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Hapus akun autentikasi Firebase
      // PENTING: Untuk menghapus akun Firebase user lain, Anda perlu
      // 1. Menggunakan Firebase Admin SDK dari backend (Cloud Functions, Node.js, dll.)
      // 2. Atau, jika Anda menghapus user yang sedang login, Anda bisa menggunakan:
      //    await _auth.currentUser!.delete();
      //    Namun, ini untuk *user yang sedang login*. Untuk admin menghapus user lain,
      //    pendekatan paling aman adalah menggunakan Firebase Admin SDK.
      //    Untuk tujuan demo ini, kita asumsikan admin bisa menghapus data Firestore saja.
      //    Jika ingin menghapus akun Firebase juga, perlu setup Cloud Functions/backend.

      // Jika user yang dihapus adalah user yang sedang login (misalnya admin menghapus akunnya sendiri),
      // maka perlu signOut setelah penghapusan
      if (_appUser != null && _appUser!.id == userId) {
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      // Tangani error jika terjadi masalah saat menghapus akun Firebase (jika diimplementasikan)
      _errorMessage =
          'Gagal menghapus akun Firebase: ${_mapFirebaseAuthError(e.code)}';
      rethrow;
    } catch (e) {
      _errorMessage = 'Gagal menghapus pengguna: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signOut();
      _appUser = null;
      _firebaseUser = null;
      _allUsers = [];
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
      case 'requires-recent-login':
        return 'Operasi ini memerlukan autentikasi ulang. Silakan login kembali.';
      default:
        return 'Gagal autentikasi. Silakan coba lagi.';
    }
  }
}
