import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livria_user/common/services/cloudinary_upload_service.dart';

class PaymentService {
  static const String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  Future<String?> uploadToCloudinary(File imageFile) =>
      CloudinaryUploadService.uploadFile(imageFile);

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