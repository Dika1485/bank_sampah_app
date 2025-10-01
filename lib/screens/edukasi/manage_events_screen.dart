import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/events_provider.dart';
import 'package:bank_sampah_app/models/event.dart';
import 'package:image_picker/image_picker.dart';

class ManageEventsPage extends StatefulWidget {
  const ManageEventsPage({super.key});

  @override
  State<ManageEventsPage> createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends State<ManageEventsPage> {
  @override
  void initState() {
    super.initState();
    // Memastikan kita mulai mendengarkan event saat widget dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventsProvider>(context, listen: false).listenToEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Acara Edukasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditAddEventDialog(context),
          ),
        ],
      ),
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
                    leading:
                        event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Image.network(
                              event.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) =>
                                  const Icon(Icons.broken_image),
                            ),
                          )
                        : const Icon(Icons.event, size: 50),
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
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      // 💡 Panggil deleteEvent dengan objek Event, bukan hanya ID
                      onPressed: () => _confirmDelete(context, event),
                    ),
                    onTap: () => _showEditAddEventDialog(context, event: event),
                  ),
                );
              },
            ),
    );
  }

  // 💡 Metode konfirmasi penghapusan
  void _confirmDelete(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Acara?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus acara "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Panggil fungsi deleteEvent di provider dengan objek Event
              Provider.of<EventsProvider>(
                context,
                listen: false,
              ).deleteEvent(event);
              Navigator.pop(context); // Tutup dialog
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 💡 Metode _showEditAddEventDialog() yang direvisi untuk Cloudinary
  void _showEditAddEventDialog(BuildContext context, {Event? event}) {
    final titleController = TextEditingController(text: event?.title);
    final descriptionController = TextEditingController(
      text: event?.description,
    );
    DateTime? selectedDate = event?.dateTime;
    TimeOfDay? selectedTime = event != null
        ? TimeOfDay(hour: event.dateTime.hour, minute: event.dateTime.minute)
        : null;

    // Gunakan StatefulBuilder untuk mengelola state lokal dialog (gambar)
    showDialog(
      context: context,
      builder: (context) {
        // State lokal untuk gambar
        File? pickedImage = event?.imageUrl != null ? null : null;
        String? existingImageUrl = event?.imageUrl;
        bool isUploading = false;

        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            Future<void> pickImageForDialog() async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
              );

              if (pickedFile != null) {
                setStateInDialog(() {
                  pickedImage = File(pickedFile.path);
                  existingImageUrl =
                      null; // Hapus URL lama jika memilih gambar baru
                });
              }
            }

            // Tentukan gambar mana yang akan ditampilkan (Preview/URL Lama/Placeholder)
            Widget imagePreview = Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: isUploading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Tampilkan loading saat upload
                  : pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(pickedImage!, fit: BoxFit.cover),
                    )
                  : existingImageUrl != null && existingImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        existingImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
            );

            return AlertDialog(
              title: Text(event == null ? 'Tambah Acara Baru' : 'Edit Acara'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 💡 Bagian Gambar
                    imagePreview,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: isUploading
                              ? null
                              : pickImageForDialog, // Disable saat upload
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            event != null
                                ? 'Ganti Foto'
                                : 'Pilih Foto (Opsional)',
                          ),
                        ),
                        if (pickedImage != null || existingImageUrl != null)
                          TextButton.icon(
                            onPressed: isUploading
                                ? null
                                : () {
                                    // Disable saat upload
                                    setStateInDialog(() {
                                      pickedImage = null;
                                      existingImageUrl =
                                          null; // Hapus URL lama/gambar baru
                                    });
                                  },
                            icon: const Icon(Icons.clear, color: Colors.red),
                            label: const Text(
                              'Hapus Foto',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bagian Input Teks
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
                    // Bagian Tanggal & Waktu
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
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
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
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          // Disable saat upload
                          // 💡 Logika Save (Tambah/Edit)
                          if (titleController.text.isNotEmpty &&
                              descriptionController.text.isNotEmpty &&
                              selectedDate != null &&
                              selectedTime != null) {
                            // 1. Gabungkan Tanggal & Waktu
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

                            // 2. Proses Upload Gambar jika ada gambar baru
                            String? finalImageUrl = existingImageUrl;
                            if (pickedImage != null) {
                              setStateInDialog(
                                () => isUploading = true,
                              ); // Mulai loading upload

                              finalImageUrl = await provider
                                  .uploadImageAndGetUrl(pickedImage!);

                              setStateInDialog(
                                () => isUploading = false,
                              ); // Hentikan loading upload

                              if (finalImageUrl == null) {
                                // Jika upload gagal, tampilkan error dan batalkan operasi
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        provider.errorMessage ??
                                            'Gagal mengunggah gambar. Operasi dibatalkan.',
                                      ),
                                    ),
                                  );
                                }
                                return; // Hentikan proses
                              }
                            } else if (existingImageUrl == null &&
                                pickedImage == null &&
                                event?.imageUrl != null) {
                              // Kasus: User menghapus gambar yang sudah ada (existingImageUrl menjadi null)
                              finalImageUrl = null;
                            }

                            // 3. Simpan data ke Firestore
                            if (event == null) {
                              final newEvent = Event(
                                id: '',
                                title: titleController.text,
                                description: descriptionController.text,
                                dateTime: newDateTime,
                                imageUrl:
                                    finalImageUrl, // Simpan URL gambar (atau null)
                              );
                              await provider.addEvent(newEvent);
                            } else {
                              final updatedEvent = Event(
                                id: event.id,
                                title: titleController.text,
                                description: descriptionController.text,
                                dateTime: newDateTime,
                                imageUrl:
                                    finalImageUrl, // Simpan URL gambar (atau null)
                              );
                              await provider.editEvent(updatedEvent);
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // Tutup dialog
                            }
                          } else {
                            // Tampilkan pesan error jika ada field wajib yang kosong
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Judul, Deskripsi, Tanggal, dan Waktu wajib diisi!',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(event == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
