import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart'; // Diperlukan untuk membuat signature

class CloudinaryService {
  // 🚫 PERINGATAN: KUNCI RAHASIA INI TERPAPAR DI KODE FRONTEND
  static const String _cloudName = 'dzjrfadjn';
  static const String _apiKey = '953858849976746';
  static const String _apiSecret =
      'B1xcEM7X5PigdKETGqNirifZse8'; // RISIKO KEAMANAN TINGGI!

  // URL Upload (Menggunakan Upload Preset - Lebih Aman untuk Upload)
  static const String _cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  static const String _cloudinaryUploadPreset = 'flutter_upload';

  // URL Penghapusan (Menggunakan API Admin - Memerlukan Signature)
  static const String _cloudinaryDeleteUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy';

  // -------------------------------------------------------------------------
  // 1. UNGGAH GAMBAR (Menggunakan Preset)
  // -------------------------------------------------------------------------

  Future<String?> uploadImage(
    File imageFile, {
    required String folderName,
  }) async {
    if (_cloudName.contains('dzjrfadjn')) {
      debugPrint('❌ ERROR: Cloudinary config is not set!');
      return null;
    }

    try {
      final uri = Uri.parse(_cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..fields['folder'] = folderName;

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'] as String;
      } else {
        debugPrint(
          '❌ Cloudinary upload gagal: ${response.statusCode}. Body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error saat Cloudinary upload: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 2. HAPUS GAMBAR (Menggunakan API Admin + Signature)
  // -------------------------------------------------------------------------

  /// Menghapus gambar dari Cloudinary berdasarkan URL gambar.
  Future<bool> deleteImageByUrl(String imageUrl) async {
    final publicId = _extractPublicId(imageUrl);
    if (publicId == null) {
      debugPrint('⚠️ Gagal mendapatkan Public ID dari URL: $imageUrl');
      return false;
    }

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();

    // String yang perlu di-hash (sortir berdasarkan nama kunci)
    // Contoh: 'public_id=folder/gambar_saya&timestamp=1678886400' + API Secret
    final params = {'public_id': publicId, 'timestamp': timestamp};

    // Sortir dan buat query string
    final sortedKeys = params.keys.toList()..sort();
    final signatureString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Buat SHA-1 Signature
    final stringToSign = signatureString + _apiSecret;
    final signature = sha1.convert(utf8.encode(stringToSign)).toString();

    try {
      final response = await http.post(
        Uri.parse(_cloudinaryDeleteUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': _apiKey,
          'signature': signature,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['result'] == 'ok') {
        debugPrint('✅ Penghapusan Public ID ($publicId) berhasil.');
        return true;
      } else {
        debugPrint(
          '❌ Gagal menghapus gambar Cloudinary. Status: ${response.statusCode}, Pesan: ${responseBody['error']['message']}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error saat menghapus gambar: $e');
      return false;
    }
  }

  /// Helper: Mengekstrak Public ID dari Cloudinary URL
  String? _extractPublicId(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return null;

    final pathSegments = uri.pathSegments;
    final uploadIndex = pathSegments.indexOf('upload');

    if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
      // Ambil path setelah versi (v<number>)
      final subPath = pathSegments.sublist(uploadIndex + 2).join('/');
      // Hapus ekstensi file
      final publicIdWithExtension = subPath.substring(0);
      final lastDotIndex = publicIdWithExtension.lastIndexOf('.');
      if (lastDotIndex != -1) {
        return publicIdWithExtension.substring(0, lastDotIndex);
      }
      return publicIdWithExtension;
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // 3. METODE KHUSUS PRODUK DAN EVENT
  // -------------------------------------------------------------------------

  Future<String?> uploadProductImage(File imageFile) {
    return uploadImage(imageFile, folderName: 'bank_sampah/products');
  }

  Future<String?> uploadEventImage(File imageFile) {
    return uploadImage(imageFile, folderName: 'bank_sampah/events');
  }
}
