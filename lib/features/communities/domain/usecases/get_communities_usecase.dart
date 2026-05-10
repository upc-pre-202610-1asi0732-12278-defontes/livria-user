
/*
* class GetUserOrdersUseCase {
  final OrderRepository repository;

  GetUserOrdersUseCase(this.repository);

  Future<List<Order>> call(int userId) async {
    return await repository.getOrdersByUser(userId);
  }
}
* */

import 'package:livria_user/features/communities/domain/entities/community.dart';
import 'package:livria_user/features/communities/domain/repositories/community_repository.dart';

class GetCommunitiesUseCase {
  final CommunityRepository repository;

  GetCommunitiesUseCase(this.repository);

  Future<List<Community>> call(int userId) async {
    return await repository.getCommunitiesByUser(userId);
  }

}