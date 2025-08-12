import 'package:bank_sampah_app/models/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Acara')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.blue[100],
              child: const Icon(Icons.event, size: 100, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              event.title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  // Menggunakan locale 'id_ID' untuk format yang lebih lengkap
                  DateFormat(
                    'EEEE, dd MMMM yyyy, HH:mm',
                    'id_ID',
                  ).format(event.dateTime),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Deskripsi Acara:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(event.description, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
