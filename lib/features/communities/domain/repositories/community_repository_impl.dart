import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/community.dart';
import '../../domain/entities/joined_community.dart'; // Importamos JoinedCommunity
import '../../domain/repositories/community_repository.dart';
import '../../infrastructure/datasource/community_remote_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource _ds;

  const CommunityRepositoryImpl(this._ds);

  @override
  Future<List<Community>> fetchCommunityList(int offset, int limit) async {
    final http.Response res = await _ds.fetchCommunityList(offset, limit);

    if (res.statusCode == 200) {
      final List<dynamic> communityJsonList = jsonDecode(res.body);
      return communityJsonList.map((jsonItem) =>
          Community.fromJson(jsonItem as Map<String, dynamic>)).toList();
    }
    throw Exception('HTTP ${res.statusCode}: Fallo al cargar la lista de comunidades');
  }

  @override
  Future<List<Community>> getCommunitiesByUser(int userId) async {
    final http.Response res = await _ds.fetchCommunitiesByUser(userId: userId);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final List<dynamic> communities = jsonDecode(res.body);
      return communities.map((jsonItem) =>
          Community.fromJson(jsonItem as Map<String, dynamic>)).toList();
    }
    throw Exception('HTTP ${res.statusCode}: Fallo al unirse a la comunidad. Mensaje: ${res.body}');
  }

  @override
  Future<List<Community>> searchCommunities(String query) async {
    const int maxLimit = 1000;
    final normalizedQuery = query.toLowerCase().trim();

    if (normalizedQuery.isEmpty) return [];

    final allCommunities = await fetchCommunityList(0, maxLimit);

    return allCommunities.where((community) {
      final nameMatches = community.name.toLowerCase().contains(normalizedQuery);
      final descriptionMatches = community.description.toLowerCase().contains(normalizedQuery);
      return nameMatches || descriptionMatches;
    }).toList();
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

    final http.Response res = await _ds.createCommunity(body);

    if (res.statusCode == 201) {
      final Map<String, dynamic> communityJson = jsonDecode(res.body);
      return Community.fromJson(communityJson);
    }
    throw Exception('HTTP ${res.statusCode}: Fallo al crear la comunidad. Mensaje: ${res.body}');
  }

  // join, leave y check

  @override
  Future<JoinedCommunity> joinCommunity({
    required int userClientId,
    required int communityId,
  }) async {
    final body = {
      "userClientId": userClientId,
      "communityId": communityId,
    };

    final http.Response res = await _ds.joinCommunity(body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final Map<String, dynamic> joinedJson = jsonDecode(res.body);
      return JoinedCommunity.fromJson(joinedJson);
    }
    throw Exception('HTTP ${res.statusCode}: Fallo al unirse a la comunidad. Mensaje: ${res.body}');
  }

  @override
  Future<void> leaveCommunity({
    required int userClientId,
    required int communityId,
  }) async {
    final http.Response res = await _ds.leaveCommunity(
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
    final http.Response res = await _ds.checkUserJoined(
      communityId: communityId,
      userId: userId,
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(res.body);
      return jsonResponse['isMember'] as bool;
    }

    throw Exception('HTTP ${res.statusCode}: Fallo al verificar la unión a la comunidad. Mensaje: ${res.body}');
  }
}