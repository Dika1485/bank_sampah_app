// validators.dart
class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Masukkan email yang valid.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong.';
    }
    if (value != password) {
      return 'Password tidak cocok.';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong.';
    }
    return null;
  }

  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong.';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName harus berupa angka.';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong.';
    }
    final numValue = double.tryParse(value);
    if (numValue == null || numValue <= 0) {
      return '$fieldName harus lebih besar dari 0.';
    }
    return null;
  }

  static String? validateNIK(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK tidak boleh kosong.';
    }
    if (value.length != 16) {
      return 'NIK harus 16 digit.';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NIK hanya boleh berisi angka.';
    }
    return null;
  }
}
