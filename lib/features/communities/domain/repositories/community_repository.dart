import '../../domain/entities/community.dart';
import '../entities/joined_community.dart';

abstract class CommunityRepository {
  Future<List<Community>> fetchCommunityList(int offset, int limit);
  Future<List<Community>> getCommunitiesByUser(int userId);
  Future<List<Community>> searchCommunities(String query);

  Future<Community> createCommunity({
    required String name,
    required String description,
    required int type,
    required int ownerId,
    required String image,
    required String banner,
  });

  /// Une al usuario a una comunidad, esperando una respuesta con la fecha de unión.
  Future<JoinedCommunity> joinCommunity({
    required int userClientId,
    required int communityId,
  });

  /// Permite al usuario salir de una comunidad. No se espera contenido de retorno (No Content - 204).
  Future<void> leaveCommunity({
    required int userClientId,
    required int communityId,
  });

  /// Verifica si el usuario ya es miembro de una comunidad específica.
  Future<bool> checkUserJoined({
    required int userId,
    required int communityId,
  });
}