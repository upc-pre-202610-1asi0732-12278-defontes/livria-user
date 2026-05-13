import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../common/config/env.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../domain/entities/order.dart';

class OrderRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _orderPath = '/api/v1/orders';

  final http.Client _client;
  OrderRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthLocalDataSource().getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // CREAR ORDEN (POST)
  Future<Order> createOrder({
    required int userClientId,
    required String userEmail,
    required String userPhone,
    required String userFullName,
    required String recipientName,
    required bool isDelivery,
    required String status,
    ShippingDetails? shippingDetails, // Opcional si es pick-up
  }) async {
    final uri = Uri.parse('$_base$_orderPath');
    final headers = await _getHeaders();

    // Construimos el body del request
    final Map<String, dynamic> requestBody = {
      "userClientId": userClientId,
      "userEmail": userEmail,
      "userPhone": userPhone,
      "userFullName": userFullName,
      "recipientName": recipientName,
      "status": status, // "PENDING", "PAID", etc.
      "isDelivery": isDelivery,
      // Solo enviamos shippingDetails si isDelivery es true y el objeto existe
      if (isDelivery && shippingDetails != null)
        "shippingDetails": shippingDetails.toMap()
    };

    debugPrint("🔵 [ORDER POST] Sending to $uri");
    debugPrint("📦 [ORDER BODY] ${json.encode(requestBody)}");

    final response = await _client.post(
      uri,
      headers: headers,
      body: json.encode(requestBody),
    );

    debugPrint("🟣 [ORDER RESPONSE] Status: ${response.statusCode}");
    debugPrint("🟣 [ORDER RESPONSE] Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Order.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }

  Future<List<Order>> getOrdersByUser(int userId) async {
    final uri = Uri.parse('$_base$_orderPath/users/$userId');
    final headers = await _getHeaders();

    debugPrint("🔵 [ORDERS GET] Fetching for user: $userId");

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return Order.listFromJson(response.body);
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }


}