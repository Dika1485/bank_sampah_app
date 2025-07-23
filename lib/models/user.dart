enum UserType { nasabah, direktur, sekretaris, bendahara, edukasi }

class AppUser {
  final String id;
  final String email;
  final String nama;
  final String nik;
  final UserType userType;
  final bool validated;
  final double balance;

  AppUser({
    required this.id,
    required this.email,
    required this.nama,
    required this.nik,
    required this.userType,
    required this.validated,
    this.balance = 0.0, // Default 0.0 jika tidak ada di Firestore
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      nama: data['nama'] ?? '',
      nik: data['nik'] ?? '',
      userType: (data['userType'] == 'direktur')
          ? UserType.direktur
          : (data['userType'] == 'sekretaris')
          ? UserType.sekretaris
          : (data['userType'] == 'bendahara')
          ? UserType.bendahara
          : (data['userType'] == 'edukasi')
          ? UserType.edukasi
          : UserType.nasabah,
      validated: data['validated'] ?? false,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0, // Ambil saldo
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nama': nama,
      'nik': nik,
      'userType': userType == UserType.direktur
          ? 'direktur'
          : userType == UserType.sekretaris
          ? 'sekretaris'
          : userType == UserType.bendahara
          ? 'bendahara'
          : userType == UserType.edukasi
          ? 'edukasi'
          : 'nasabah',
      'validated': validated,
      'balance': balance, // Simpan saldo
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? nama,
    String? nik,
    UserType? userType,
    double? balance,
    bool? validated,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      nama: nama ?? this.nama,
      nik: nik ?? this.nik,
      userType: userType ?? this.userType,
      balance: balance ?? this.balance,
      validated: validated ?? this.validated,
    );
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
