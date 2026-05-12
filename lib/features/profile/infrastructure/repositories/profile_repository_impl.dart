import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasource/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserProfile> getUserProfile(int userId) async {
    return await remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<UserProfile> updateUserProfile(int userId, UserProfile updatedProfile) async {
    return await remoteDataSource.updateUserProfile(userId, updatedProfile);
  }

  @override
  Future<void> deleteCommunity(int communityId, int ownerId) async {
    await remoteDataSource.deleteCommunity(communityId, ownerId);
  }

  @override
  Future<void> deleteAccount(int userId) async {
    await remoteDataSource.deleteAccount(userId);
  }

  @override
  Future<UserProfile> updateSubscription(int userId, String newPlan) async {
    return await remoteDataSource.updateSubscription(userId, newPlan);
  }
}