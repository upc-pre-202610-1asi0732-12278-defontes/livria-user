import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/community.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/joined_community.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasource/community_remote_datasource.dart';

class CommunityRepositoryApi implements CommunityRepository {
  final CommunityRemoteDataSource _dataSource;

  const CommunityRepositoryApi({required CommunityRemoteDataSource dataSource})
      : _dataSource = dataSource;

  Community _mapCommunity(String responseBody) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(responseBody);
      return Community.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to parse community JSON: $e');
    }
  }

  List<Community> _mapCommunityList(String responseBody) {
    try {
      final List<dynamic> jsonList = json.decode(responseBody);
      return jsonList.map((json) => Community.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to parse community list JSON: $e');
    }
  }

  JoinedCommunity _mapJoinedCommunity(String responseBody) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(responseBody);
      return JoinedCommunity.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to parse joined community JSON: $e');
    }
  }

  Post _mapPost(String responseBody) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(responseBody);
      return Post.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to parse post JSON: $e');
    }
  }

  List<Post> _mapPostList(String responseBody) {
    try {
      final List<dynamic> jsonList = json.decode(responseBody);
      return jsonList.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to parse post list JSON: $e');
    }
  }

  @override
  Future<List<Community>> fetchCommunityList(int offset, int limit) async {
    final http.Response response = await _dataSource.fetchCommunityList(offset, limit);

    if (response.statusCode == 200) {
      return _mapCommunityList(response.body);
    } else {
      throw Exception('Failed to load communities. Status: ${response.statusCode}');
    }
  }

  @override
  Future<List<Community>> getCommunitiesByUser(int userClientId) async {
    final http.Response response = await _dataSource.fetchCommunitiesByUser(userId: userClientId);

    if (response.statusCode == 200) {
      return _mapCommunityList(response.body);
    } else {
      throw Exception('Failed to load communities. Status: ${response.statusCode}');
    }
  }

  @override
  Future<List<Community>> searchCommunities(String query) async {
    final http.Response response = await _dataSource.fetchCommunityList(0, 100);

    if (response.statusCode == 200) {
      final allCommunities = _mapCommunityList(response.body);

      if (query.isEmpty) {
        return allCommunities;
      }
      final normalizedQuery = query.toLowerCase().trim();
      return allCommunities.where((community) {
        return community.name.toLowerCase().contains(normalizedQuery) ||
            community.description.toLowerCase().contains(normalizedQuery);
      }).toList();

    } else {
      throw Exception('Failed to search communities. Status: ${response.statusCode}');
    }
  }

  @override
  Future<Community> createCommunity({
    required String name,
    required String description,
    required int type,
    required int ownerId,
    required String image,
    required String banner,
  }) async {
    final body = {
      "name": name,
      "description": description,
      "type": type,
      "ownerId": ownerId,
      "image": image,
      "banner": banner,
    };

    final http.Response res = await _dataSource.createCommunity(body);

    if (res.statusCode == 201) {
      return _mapCommunity(res.body);
    }
    throw Exception('HTTP ${res.statusCode}: Fallo al crear la comunidad. Mensaje: ${res.body}');
  }

  @override
  Future<JoinedCommunity> joinCommunity({
    required int userClientId,
    required int communityId,
  }) async {
    final body = {
      "userClientId": userClientId,
      "communityId": communityId,
    };

    final http.Response res = await _dataSource.joinCommunity(body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return _mapJoinedCommunity(res.body);
    }
    throw Exception('HTTP ${res.statusCode}: Fallo al unirse a la comunidad. Mensaje: ${res.body}');
  }

  @override
  Future<void> leaveCommunity({
    required int userClientId,
    required int communityId,
  }) async {
    final http.Response res = await _dataSource.leaveCommunity(
      communityId: communityId,
      userId: userClientId,
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    throw Exception('HTTP ${res.statusCode}: Fallo al salir de la comunidad. Mensaje: ${res.body}');
  }

  @override
  Future<bool> checkUserJoined({
    required int userId,
    required int communityId,
  }) async {
    final http.Response res = await _dataSource.checkUserJoined(
      communityId: communityId,
      userId: userId,
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(res.body);
      return jsonResponse['isMember'] as bool;
    }

    throw Exception('HTTP ${res.statusCode}: Fallo al verificar la unión a la comunidad. Mensaje: ${res.body}');
  }
}