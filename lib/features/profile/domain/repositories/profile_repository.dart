import '../entities/user_profile.dart';

abstract class ProfileRepository {
  // Obtener perfil
  Future<UserProfile> getUserProfile(int userId);

  // Actualizar perfil
  Future<UserProfile> updateUserProfile(int userId, UserProfile updatedProfile);

  // Eliminar comunidad propia
  Future<void> deleteCommunity(int communityId, int ownerId);

  // Borrar cuenta
  Future<void> deleteAccount(int userId);

  Future<UserProfile> updateSubscription(int userId, String newPlan);
}