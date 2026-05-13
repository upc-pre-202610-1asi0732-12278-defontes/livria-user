import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'dart:convert';

class ExclusionRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _userClientsPath = '/api/v1/userclients';

  final http.Client _client;
  final AuthLocalDataSource authDs;

  ExclusionRemoteDataSource({
    http.Client? client,
    required this.authDs,
  }) : _client = client ?? http.Client();

  Future<void> postExclusion({
    required int userId,
    required int bookId,
  }) async {
    final String path = '$_userClientsPath/$userId/exclusions/$bookId';
    final uri = Uri.parse('$_base$path');

    final token = await authDs.getToken();

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception('Failed to add to exclusions. Status: ${response.statusCode}. Body: ${response.body}');
    }
  }

  Future<void> deleteExclusion({
    required int userId,
    required int bookId,
  }) async {
    final String path = '$_userClientsPath/$userId/exclusions/$bookId';
    final uri = Uri.parse('$_base$path');

    final token = await authDs.getToken();

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Failed to remove exclusion. Status: ${response.statusCode}');
    }
  }

  Future<bool> getExclusionStatus({
    required int userId,
    required int bookId,
  }) async {
    final String path = '$_userClientsPath/$userId/exclusions';
    final uri = Uri.parse('$_base$path');

    final token = await authDs.getToken();

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> exclusionsJson = json.decode(response.body);

      final bool isExcluded = exclusionsJson.any((exc) => exc['id'] == bookId);

      return isExcluded;
    } else {
      throw Exception('Failed to load exclusions list. Status: ${response.statusCode}');
    }
  }

  Future<List<int>> getExclusionsList({
    required int userId,
  }) async {
    final String path = '$_userClientsPath/$userId/exclusions';
    final uri = Uri.parse('$_base$path');

    final token = await authDs.getToken();

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> exclusionsJson = json.decode(response.body);

      final List<int> excludedIds = exclusionsJson
          .map((exc) => exc['id'] as int)
          .toList();

      return excludedIds;
    } else {
      throw Exception('Failed to load complete exclusions list. Status: ${response.statusCode}');
    }
  }
}