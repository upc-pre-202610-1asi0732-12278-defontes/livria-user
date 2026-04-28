import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:http/http.dart' as http;

class PaymentService {
  static const String _cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dd2fmyphr/image/upload';
  static const String _uploadPreset = 'livria_preset';
  static const String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint("Error en Cloudinary: $e");
      return null;
    }
  }

  Future<bool> sendEmail({
    required String serviceId,
    required String templateId,
    required String publicKey,
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': params,
        }),
      );

      // --- LOGS DE DEBUGGING ---
      debugPrint("Status Code EmailJS: ${response.statusCode}");
      debugPrint("Response Body EmailJS: ${response.body}");
      // -------------------------

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error fatal en la petición HTTP: $e");
      return false;
    }
  }
}