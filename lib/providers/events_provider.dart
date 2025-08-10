// lib/providers/events_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_sampah_app/models/event.dart';

class EventsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _eventsSubscription;

  // Pastikan untuk membatalkan subscription saat provider di-dispose
  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

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

  // Menambahkan acara baru ke Firestore
  Future<void> addEvent(Event newEvent) async {
    try {
      await _firestore.collection('events').add(newEvent.toFirestore());
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menambahkan acara: ${e.message}';
      notifyListeners();
    }
  }

  // Mengedit acara yang sudah ada di Firestore
  Future<void> editEvent(Event updatedEvent) async {
    try {
      await _firestore
          .collection('events')
          .doc(updatedEvent.id)
          .update(updatedEvent.toFirestore());
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal mengedit acara: ${e.message}';
      notifyListeners();
    }
  }

  // Menghapus acara dari Firestore
  Future<void> deleteEvent(String id) async {
    try {
      await _firestore.collection('events').doc(id).delete();
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menghapus acara: ${e.message}';
      notifyListeners();
    }
  }
}
