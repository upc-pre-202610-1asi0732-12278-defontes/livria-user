import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';
import '../../domain/entities/cart_item.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';


class CartRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _cartPath = '/api/v1/cart-items';

  final http.Client _client;

  CartRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();


  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthLocalDataSource().getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // OBTENER EL CARRITO (GET)
  Future<List<CartItem>> getCartItems(int userId) async {
    final uri = Uri.parse('$_base$_cartPath/users/$userId');
    final headers = await _getHeaders();

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return CartItem.listFromJson(response.body);
    } else {
      throw Exception('Error loading cart (${response.statusCode})');
    }
  }

  // AGREGAR ITEM (POST)
  Future<void> addToCart(int bookId, int quantity, int userId) async {
    final uri = Uri.parse('$_base$_cartPath');
    final headers = await _getHeaders();

    final body = json.encode({
      "bookId": bookId,
      "quantity": quantity,
      "userClientId": userId
    });

    debugPrint("🔵 [CART REQUEST] Sending to $uri");

    final response = await _client.post(
      uri,
      headers: headers, // Enviamos el token aquí
      body: body,
    );

    debugPrint("🟣 [CART RESPONSE] Status: ${response.statusCode}");
    debugPrint('🛒 [CART POST] status: ${response.statusCode}');
    debugPrint('🛒 [CART POST] body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      // Si el token expiró (401) o hay otro error
      throw Exception('Server Error ${response.statusCode}: ${response.body}');
    }
  }

  // ACTUALIZAR CANTIDAD (PUT)
  Future<void> updateQuantity(int cartItemId, int userId, int newQuantity) async {
    final uri = Uri.parse('$_base$_cartPath/$cartItemId/users/$userId');
    final headers = await _getHeaders();
    final body = json.encode({"newQuantity": newQuantity});

    final response = await _client.put(uri, headers: headers, body: body);

    // CORRECCIÓN: A veces PUT también devuelve 204
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error updating cart (${response.statusCode})');
    }
  }

  // ELIMINAR ITEM (DELETE)
  Future<void> deleteItem(int cartItemId, int userId) async {
    final uri = Uri.parse('$_base$_cartPath/$cartItemId/users/$userId');
    final headers = await _getHeaders();

    debugPrint("🔵 [DELETE REQUEST] Deleting item $cartItemId");

    final response = await _client.delete(uri, headers: headers);

    debugPrint("🟣 [DELETE RESPONSE] Status: ${response.statusCode}");

    // CORRECCIÓN AQUÍ: Aceptamos 200 (OK) y 204 (No Content)
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error deleting item (${response.statusCode})');
    }
  }
}