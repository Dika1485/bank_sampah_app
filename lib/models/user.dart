enum UserType { nasabah, pengepul }

class AppUser {
  final String id;
  final String email;
  final String nama;
  final String nik;
  final String noKtp; // Mungkin path URL gambar KTP atau string NIK
  final UserType userType;

  AppUser({
    required this.id,
    required this.email,
    required this.nama,
    required this.nik,
    required this.noKtp,
    required this.userType,
  });

  // Factory constructor untuk membuat objek AppUser dari Firestore Document
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      nama: data['nama'] ?? '',
      nik: data['nik'] ?? '',
      noKtp: data['noKtp'] ?? '',
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
      'noKtp': noKtp,
      'userType': userType == UserType.nasabah ? 'nasabah' : 'pengepul',
    };
  }
}
