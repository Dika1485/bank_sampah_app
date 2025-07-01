// app_constants.dart
class AppConstants {
  static const String appName = 'Bank Sampah App';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String sampahPricesCollection = 'sampah_prices';
  static const String transactionsCollection = 'transactions';

  // User Types
  static const String userTypeNasabah = 'nasabah';
  static const String userTypePengepul = 'pengepul';

  // Transaction Types
  static const String transactionTypeSetoran = 'setoran';
  static const String transactionTypePencairan = 'pencairan';

  // Transaction Statuses
  static const String transactionStatusPending = 'pending';
  static const String transactionStatusCompleted = 'completed';
  static const String transactionStatusRejected = 'rejected';

  // Other constants (e.g., image upload paths)
  static const String ktpImagesStoragePath = 'ktp_images';
}
