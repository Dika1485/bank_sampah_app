enum UserType { nasabah, pengepul }

class AppUser {
  final String id;
  final String email;
  final String nama;
  final String nik;
  final UserType userType;
  final double balance;

  AppUser({
    required this.id,
    required this.email,
    required this.nama,
    required this.nik,
    required this.userType,
    this.balance = 0.0, // Default 0.0 jika tidak ada di Firestore
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      nama: data['nama'] ?? '',
      nik: data['nik'] ?? '',
      userType: (data['userType'] == 'nasabah')
          ? UserType.nasabah
          : UserType.pengepul,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0, // Ambil saldo
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nama': nama,
      'nik': nik,
      'userType': userType == UserType.nasabah ? 'nasabah' : 'pengepul',
      'balance': balance, // Simpan saldo
    };
  }

  @override
  bool operator ==(Object other) {
    // Dua objek AppUser dianggap sama jika ID-nya sama
    if (identical(this, other))
      return true; // Jika objeknya sama persis di memori
    return other is AppUser && // Jika 'other' adalah objek AppUser
        other.id == id; // Dan ID-nya sama
  }

  @override
  int get hashCode => id.hashCode; // Hash code harus berdasarkan ID
}
