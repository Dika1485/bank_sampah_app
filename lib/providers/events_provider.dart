import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/event.dart';
import 'package:bank_sampah_app/services/cloudinary_service.dart';

class EventsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 💡 Inisialisasi service Cloudinary
  final CloudinaryService _cloudinaryService = CloudinaryService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _eventsSubscription;

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // READ (LISTEN)
  // -------------------------------------------------------------------

  // Mengambil data acara secara real-time dari Firestore
  void listenToEvents() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _eventsSubscription?.cancel();
    _eventsSubscription = _firestore
        .collection('events')
        .orderBy('dateTime', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            // Pastikan Event.fromFirestore sudah mendukung imageUrl
            _events = snapshot.docs
                .map((doc) => Event.fromFirestore(doc.data(), doc.id))
                .toList();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = 'Gagal memuat acara: $error';
            notifyListeners();
          },
        );
  }

  // -------------------------------------------------------------------
  // IMAGE UPLOAD (MENGGUNAKAN CLOUDINARY SERVICE)
  // -------------------------------------------------------------------

  /// Mengunggah gambar ke Cloudinary dan mendapatkan URL
  /// Dipanggil sebelum memanggil addEvent/editEvent.
  Future<String?> uploadImageAndGetUrl(File imageFile) async {
    try {
      // Tidak perlu set _isLoading di sini, biarkan UI (ManageEventsScreen) menanganinya
      // atau set saja error message.

      // Panggil metode upload khusus event dari CloudinaryService
      final imageUrl = await _cloudinaryService.uploadEventImage(imageFile);

      // Jika upload berhasil, imageUrl akan berisi URL. Jika gagal, imageUrl adalah null.
      if (imageUrl == null) {
        // Asumsikan CloudinaryService sudah mencetak error, kita hanya perlu menanggapi.
        _errorMessage = 'Gagal mengunggah gambar acara. Cek koneksi Anda.';
      } else {
        _errorMessage = null;
      }

      notifyListeners();
      return imageUrl;
    } catch (e) {
      _errorMessage = 'Kesalahan tak terduga saat mengunggah gambar: $e';
      notifyListeners();
      return null;
    }
  }

  // -------------------------------------------------------------------
  // CREATE & UPDATE
  // -------------------------------------------------------------------

  // Menambahkan acara baru ke Firestore
  Future<void> addEvent(Event newEvent) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Data Firestore kini menyertakan imageUrl
      await _firestore.collection('events').add(newEvent.toFirestore());
      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal menambahkan acara: ${e.message}';
      notifyListeners();
    }
  }

  // Mengedit acara yang sudah ada di Firestore
  Future<void> editEvent(Event updatedEvent) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Data Firestore kini menyertakan imageUrl (yang mungkin null/baru)
      await _firestore
          .collection('events')
          .doc(updatedEvent.id)
          .update(updatedEvent.toFirestore());
      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal mengedit acara: ${e.message}';
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------
  // DELETE
  // -------------------------------------------------------------------

  /// Menghapus acara dari Firestore dan gambar terkait dari Cloudinary
  Future<void> deleteEvent(Event eventToDelete) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. Hapus gambar dari Cloudinary (jika ada)
      if (eventToDelete.imageUrl != null &&
          eventToDelete.imageUrl!.isNotEmpty) {
        final success = await _cloudinaryService.deleteImageByUrl(
          eventToDelete.imageUrl!,
        );

        if (!success) {
          // Jika hapus gambar gagal (tapi kita tidak ingin memblokir hapus data utama)
          debugPrint(
            '⚠️ Peringatan: Gagal menghapus gambar Cloudinary untuk event ID ${eventToDelete.id}. Dokumen Firestore tetap akan dihapus.',
          );
        }
      }

      // 2. Hapus dokumen Firestore
      await _firestore.collection('events').doc(eventToDelete.id).delete();

      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal menghapus acara: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          'Kesalahan saat menghapus acara dan gambar: ${e.toString()}';
      notifyListeners();
    }
  }
}
