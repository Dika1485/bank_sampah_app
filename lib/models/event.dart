import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.imageUrl,
  });

  // Metode untuk mengubah objek Event menjadi Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'imageUrl': imageUrl,
    };
  }

  // Factory constructor untuk membuat objek Event dari data Firestore
  factory Event.fromFirestore(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }
}
