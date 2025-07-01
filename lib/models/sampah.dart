enum SampahCategory { organik, anorganik }

class SampahType {
  final String id; // ID dari Firestore document
  final String name; // Contoh: "Plastik PET", "Kertas Kardus", "Sisa Makanan"
  final SampahCategory category;
  final double pricePerKg; // Harga per kg yang ditentukan pengepul

  SampahType({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerKg,
  });

  factory SampahType.fromFirestore(Map<String, dynamic> data, String id) {
    return SampahType(
      id: id,
      name: data['name'] ?? '',
      category: (data['category'] == 'organik')
          ? SampahCategory.organik
          : SampahCategory.anorganik,
      pricePerKg: (data['pricePerKg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category == SampahCategory.organik ? 'organik' : 'anorganik',
      'pricePerKg': pricePerKg,
    };
  }
}
