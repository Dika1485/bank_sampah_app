import 'package:bank_sampah_app/screens/admin/admin_dashboard_screen.dart';
import 'package:bank_sampah_app/screens/admin/user_validation_screen.dart';
import 'package:bank_sampah_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/models/user.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  // Fungsi untuk menampilkan dialog edit user
  void _showEditUserDialog(BuildContext context, AppUser userToEdit) {
    // Tambahkan Form Key di sini
    final _formKey = GlobalKey<FormState>();

    final TextEditingController nameController = TextEditingController(
      text: userToEdit.nama,
    );
    final TextEditingController nikController = TextEditingController(
      text: userToEdit.nik,
    );
    UserType selectedUserType = userToEdit.userType;
    bool isValidated = userToEdit.validated;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Pengguna'),
              content: SingleChildScrollView(
                child: Form(
                  // <-- Bungkus dengan Form
                  key: _formKey, // <-- Pasang key
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- NAMA ---
                      TextFormField(
                        // <-- Ubah menjadi TextFormField
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        // Terapkan validator untuk Nama
                        validator: (value) =>
                            AppValidators.validateRequired(value, 'Nama'),
                      ),
                      // --- NIK ---
                      TextFormField(
                        // <-- Ubah menjadi TextFormField
                        controller: nikController,
                        decoration: const InputDecoration(labelText: 'NIK'),
                        keyboardType: TextInputType.number,
                        // Terapkan validator untuk NIK
                        validator: (value) => AppValidators.validateNIK(value),
                      ),
                      // --- TIPE PENGGUNA (DropdownButtonFormField sudah mendukung validasi) ---
                      DropdownButtonFormField<UserType>(
                        value: selectedUserType,
                        decoration: const InputDecoration(
                          labelText: 'Tipe Pengguna',
                        ),
                        // ... (Item dan onChanged Anda tetap sama) ...
                        items: UserType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.toString().split('.').last.toUpperCase(),
                            ),
                          );
                        }).toList(),
                        onChanged: (UserType? newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedUserType = newValue;
                            });
                          }
                        },
                      ),
                      Row(
                        children: [
                          const Text('Validasi Akun:'),
                          Switch(
                            value: isValidated,
                            onChanged: (bool value) {
                              setDialogState(() {
                                isValidated = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // --- TRIGGER VALIDASI DI SINI ---
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop();
                      try {
                        await Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).updateUserData(
                          userId: userToEdit.id,
                          nama: nameController.text,
                          nik: nikController.text,
                          userType: selectedUserType,
                          validated: isValidated,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Akun ${userToEdit.nama} berhasil diperbarui!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal memperbarui akun: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        debugPrint('Error updating user: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi delete user
  void _confirmDeleteUser(BuildContext context, AppUser userToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun ${userToDelete.nama}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).deleteUser(userToDelete.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Akun ${userToDelete.nama} berhasil dihapus!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus akun: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  debugPrint('Error deleting user: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && authProvider.allUsers.isEmpty) {
            return const LoadingIndicator();
          }

          if (authProvider.errorMessage != null) {
            return Center(child: Text('Error: ${authProvider.errorMessage}'));
          }

          final allUsers = authProvider.allUsers;

          if (allUsers.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada pengguna terdaftar.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: allUsers.length,
            itemBuilder: (context, index) {
              final user = allUsers[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user.nama,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // --- POPUP MENU UNTUK EDIT/DELETE ---
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditUserDialog(context, user);
                              } else if (value == 'delete') {
                                _confirmDeleteUser(context, user);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit Pengguna'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Hapus Pengguna',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                          // ------------------------------------
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${user.email}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'NIK: ${user.nik}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Tipe: ${user.userType.toString().split('.').last.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Status Validasi: ${user.validated ? 'Valid' : 'Belum Valid'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: user.validated ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
