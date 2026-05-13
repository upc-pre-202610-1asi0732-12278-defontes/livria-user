import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Subida sin firmar a Cloudinary (mismo cloud y preset que [PaymentService]).
class CloudinaryUploadService {
  CloudinaryUploadService._();

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/dd2fmyphr/image/upload';
  static const String _uploadPreset = 'livria_preset';

  static Future<String?> uploadFile(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        debugPrint(
            'Cloudinary upload failed: ${streamed.statusCode} $body');
        return null;
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (e, st) {
      debugPrint('Cloudinary upload error: $e\n$st');
      return null;
    }
  }

  static Future<String?> uploadBytes(
    Uint8List bytes, {
    String filename = 'upload.jpg',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        debugPrint(
            'Cloudinary upload failed: ${streamed.statusCode} $body');
        return null;
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (e, st) {
      debugPrint('Cloudinary upload error: $e\n$st');
      return null;
    }
  }
}
