import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/events_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:bank_sampah_app/widgets/event_card.dart'; // Menggunakan EventCard yang sudah dibuat sebelumnya

class AllEventsScreen extends StatelessWidget {
  const AllEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Acara')),
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          if (eventsProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (eventsProvider.events.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada acara mendatang.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Menggunakan ListView.builder untuk menampilkan daftar acara
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: eventsProvider.events.length,
            itemBuilder: (context, index) {
              final event = eventsProvider.events[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: EventCard(event: event),
              );
            },
          );
        },
      ),
    );
  }
}
