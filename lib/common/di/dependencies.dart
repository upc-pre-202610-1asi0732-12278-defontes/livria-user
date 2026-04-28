import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../features/auth/infrastructure/datasource/auth_remote_datasource.dart';
import '../../features/auth/infrastructure/repositories/auth_repository_impl.dart';

late LoginUseCase loginUseCase;
late RegisterUseCase registerUseCase;
late CheckAuthStatusUseCase checkAuthStatusUseCase;
late LogoutUseCase logoutUseCase;
late AuthLocalDataSource authLocalDataSource;

Future<void> initializeDependencies() async {
  // Externos
  final httpClient = http.Client();

  // Data Sources
  final authRemoteDataSource = AuthRemoteDataSource(client: httpClient);
  authLocalDataSource = AuthLocalDataSource();

  // Repositorios
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );

  // Casos de Uso
  loginUseCase = LoginUseCase(authRepository);
  registerUseCase = RegisterUseCase(authRepository);
  checkAuthStatusUseCase = CheckAuthStatusUseCase(authRepository);
  logoutUseCase = LogoutUseCase(authRepository);
}
