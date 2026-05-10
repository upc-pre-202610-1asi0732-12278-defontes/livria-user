import '../../domain/entities/community.dart';
import '../repositories/community_repository.dart';

/// Caso de uso para crear una nueva comunidad.
class CreateCommunityUseCase {
  final CommunityRepository _repository;

  CreateCommunityUseCase(this._repository);

  Future<Community> call({
    required String name,
    required String description,
    required int type,
    required int ownerId,
    required String image,
    required String banner,
  }) async {
    return _repository.createCommunity(
      name: name,
      description: description,
      type: type,
      ownerId: ownerId,
      image: image,
      banner: banner,
    );
  }
}