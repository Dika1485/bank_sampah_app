enum UserType { nasabah, pengepul }

class AppUser {
  final String id;
  final String email;
  final String nama;
  final String nik;
  // Properti noKtp dihapus

  final UserType userType;

  AppUser({
    required this.id,
    required this.email,
    required this.nama,
    required this.nik,
    // noKtp dihapus dari konstruktor
    required this.userType,
  });

  // Factory constructor untuk membuat objek AppUser dari Firestore Document
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      nama: data['nama'] ?? '',
      nik: data['nik'] ?? '',
      // noKtp tidak lagi dimuat dari Firestore
      userType: (data['userType'] == 'nasabah')
          ? UserType.nasabah
          : UserType.pengepul,
    );
  }

  // Metode untuk mengonversi objek AppUser ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nama': nama,
      'nik': nik,
      // noKtp tidak lagi disimpan ke Firestore
      'userType': userType == UserType.nasabah ? 'nasabah' : 'pengepul',
    };
  }
}
