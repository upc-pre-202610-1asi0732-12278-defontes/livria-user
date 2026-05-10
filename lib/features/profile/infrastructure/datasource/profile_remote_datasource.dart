import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../../../common/config/env.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../domain/entities/user_profile.dart';

class ProfileRemoteDataSource {
  static const String _base = Env.apiBase;
  static const String _userPath = '/api/v1/userclients';
  static const String _communityPath = '/api/v1/communities';

  final http.Client _client;
  ProfileRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthLocalDataSource().getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET: Obtener datos del perfil
  Future<UserProfile> getUserProfile(int userId) async {
    final uri = Uri.parse('$_base$_userPath/$userId');
    final headers = await _getHeaders();

    debugPrint("🔵 [PROFILE GET] Requesting: $uri");

    final response = await _client.get(uri, headers: headers);

    debugPrint("🟣 [PROFILE GET] Response: ${response.statusCode}");

    if (response.statusCode == 200) {
      return UserProfile.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  // PUT: Actualizar datos del perfil
  Future<UserProfile> updateUserProfile(int userId, UserProfile updatedProfile) async {
    final uri = Uri.parse('$_base$_userPath/$userId');
    final headers = await _getHeaders();
    final body = json.encode(updatedProfile.toMap());

    debugPrint("🔵 [PROFILE PUT] Updating: $uri");
    debugPrint("📦 [BODY]: $body");

    final response = await _client.put(uri, headers: headers, body: body);

    debugPrint("🟣 [PROFILE PUT] Response: ${response.statusCode}");

    if (response.statusCode == 200) {
      return UserProfile.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // DELETE: Borrar comunidad del usuario
  Future<void> deleteCommunity(int communityId, int ownerId) async {
    final uri = Uri.parse('$_base$_communityPath/$communityId/$ownerId');
    final headers = await _getHeaders();

    debugPrint("🔴 [COMMUNITY DELETE] Deleting community: $uri");

    final response = await _client.delete(uri, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete community: ${response.body}');
    }

  }

  // DELETE: Borrar cuenta
  Future<void> deleteAccount(int userId) async {
    final uri = Uri.parse('$_base$_userPath/$userId');
    final headers = await _getHeaders();

    debugPrint("🔴 [PROFILE DELETE] Deleting account: $uri");

    final response = await _client.delete(uri, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete account: ${response.body}');
    }
  }

  // PUT: Actualizar Plan de Suscripción
  Future<UserProfile> updateSubscription(int userId, String newPlan) async {
    final uri = Uri.parse('$_base$_userPath/$userId/subscription');
    final headers = await _getHeaders();
    final body = json.encode({"newSubscriptionPlan": newPlan});

    final response = await _client.put(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      return UserProfile.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to update plan: ${response.body}');
    }
  }
}