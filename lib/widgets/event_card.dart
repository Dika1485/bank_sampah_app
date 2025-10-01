import 'package:bank_sampah_app/models/event.dart';
import 'package:bank_sampah_app/screens/nasabah/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah ada URL gambar yang valid
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(right: 16),
      elevation: 2,
      child: InkWell(
        // Menggunakan InkWell agar seluruh Card dapat diklik
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💡 Bagian Gambar/Placeholder
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: hasImage
                        ? null
                        : Colors
                              .blue[100], // Warna background jika tanpa gambar
                  ),
                  child: hasImage
                      ? Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          // Tambahkan errorBuilder jika gambar gagal dimuat
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.red[300],
                              ),
                            );
                          },
                          // Tambahkan loadingBuilder untuk UX yang lebih baik
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.event,
                            size: 50,
                            color: Colors.blue,
                          ),
                        ),
                ),
              ),

              // --------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Pastikan Anda sudah mengimpor package intl dan mengatur locale di MaterialApp
                      DateFormat(
                        'dd MMM, HH:mm',
                        'id_ID',
                      ).format(event.dateTime),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // onPressed tombol ini diarahkan ke detail screen.
                        // Anda dapat menghapus tombol ini jika menggunakan onTap pada InkWell di atas.
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventDetailScreen(event: event),
                            ),
                          );
                        },
                        child: const Text(
                          'Detail',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
