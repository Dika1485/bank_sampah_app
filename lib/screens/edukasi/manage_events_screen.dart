// lib/screens/edukasi/manage_events_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/events_provider.dart';
import 'package:bank_sampah_app/models/event.dart';

class ManageEventsPage extends StatefulWidget {
  const ManageEventsPage({super.key});

  @override
  State<ManageEventsPage> createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends State<ManageEventsPage> {
  @override
  void initState() {
    super.initState();
    // Memanggil metode untuk mendengarkan acara real-time saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventsProvider>(context, listen: false).listenToEvents();
    });
  }

  // ... sisa kode di bawah ini sama dengan sebelumnya, tidak perlu diubah.
  // Logika _showEditAddEventDialog dan UI lainnya tetap sama.

  @override
  Widget build(BuildContext context) {
    // Membaca state dari provider
    final eventsProvider = Provider.of<EventsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Acara Edukasi')),
      body: eventsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventsProvider.errorMessage != null
          ? Center(child: Text('Error: ${eventsProvider.errorMessage}'))
          : eventsProvider.events.isEmpty
          ? const Center(
              child: Text(
                'Belum ada acara. Tambahkan acara baru!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventsProvider.events.length,
              itemBuilder: (context, index) {
                final event = eventsProvider.events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    title: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(event.description),
                        const SizedBox(height: 8),
                        Text(
                          'Waktu: ${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year} Pukul ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => eventsProvider.deleteEvent(event.id),
                    ),
                    onTap: () => _showEditAddEventDialog(context, event: event),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditAddEventDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Metode _showEditAddEventDialog() tetap sama seperti sebelumnya
  // ...
  void _showEditAddEventDialog(BuildContext context, {Event? event}) {
    final titleController = TextEditingController(text: event?.title);
    final descriptionController = TextEditingController(
      text: event?.description,
    );
    DateTime? selectedDate = event?.dateTime;
    TimeOfDay? selectedTime = event != null
        ? TimeOfDay(hour: event.dateTime.hour, minute: event.dateTime.minute)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(event == null ? 'Tambah Acara Baru' : 'Edit Acara'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Acara',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedDate == null
                            ? 'Pilih Tanggal'
                            : 'Tanggal: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setStateInDialog(() => selectedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        selectedTime == null
                            ? 'Pilih Waktu'
                            : 'Waktu: ${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setStateInDialog(() => selectedTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        descriptionController.text.isNotEmpty &&
                        selectedDate != null &&
                        selectedTime != null) {
                      final newDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      final provider = Provider.of<EventsProvider>(
                        context,
                        listen: false,
                      );

                      if (event == null) {
                        final newEvent = Event(
                          id: '', // ID akan dibuat otomatis oleh Firestore
                          title: titleController.text,
                          description: descriptionController.text,
                          dateTime: newDateTime,
                        );
                        provider.addEvent(newEvent);
                      } else {
                        final updatedEvent = Event(
                          id: event.id,
                          title: titleController.text,
                          description: descriptionController.text,
                          dateTime: newDateTime,
                        );
                        provider.editEvent(updatedEvent);
                      }

                      Navigator.pop(context);
                    }
                  },
                  child: Text(event == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
