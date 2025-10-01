import 'package:bank_sampah_app/models/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah ada URL gambar yang valid
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Acara')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💡 Bagian Gambar/Placeholder yang Direvisi
            Container(
              height:
                  250, // Tinggikan sedikit untuk tampilan detail yang lebih baik
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasImage ? null : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
                boxShadow: hasImage
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover, // Memastikan gambar menutupi area
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.red[300],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.event, size: 100, color: Colors.blue),
                      ),
              ),
            ),
            // -------------------------------------------------------------
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
