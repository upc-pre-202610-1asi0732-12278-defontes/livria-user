// us13_auth_repository_impl_test.dart
// US13 – Core Integration Test
// Valida que AuthRepositoryImpl orquesta correctamente
// AuthRemoteDataSource + AuthLocalDataSource
// Framework: flutter_test + mockito | Patrón: Arrange – Act – Assert

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Importamos UserModel para el mock en lugar de UserEntity
import 'package:livria_user/features/auth/infrastructure/model/user_model.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_remote_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/repositories/auth_repository_impl.dart';

// El nombre del archivo en minúsculas según la convención de Dart
import 'us13_auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthRemoteDataSource, AuthLocalDataSource])
void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockAuthLocalDataSource mockLocal;
  late AuthRepositoryImpl sut;

  // Usuario de prueba que devuelve el servidor (usando UserModel y el ID como String)
  final fakeUser = UserModel(
    id:       "1",
    username: "lector01",
    email:    "lector@livria.com",
    display:  "Lector de Prueba",
    icon:     "",
    phrase:   "I love books",
    subscription: "freeplan",
  );

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockLocal  = MockAuthLocalDataSource();
    sut = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource:  mockLocal,
    );
  });

  // ----------------------------------------------------------------
  // AC1 – Registro exitoso y autenticación automática
  // ----------------------------------------------------------------
  group('AC1 – Registro de nueva cuenta', () {
    test(
      'register llama al remote, guarda token localmente '
      'y retorna el UserEntity del usuario recién creado',
      () async {
        // Arrange
        const fakeToken  = 'jwt.token.fake';
        const fakeUserId = 1;

        // El servidor acepta el registro
        when(mockRemote.register(any)).thenAnswer((_) async => {});

        // El login automático post-registro devuelve token + userId
        when(mockRemote.signIn("lector01", "SecurePass123"))
            .thenAnswer((_) async => {
                  'token':  fakeToken,
                  'userId': fakeUserId,
                });

        // Guardar credenciales localmente no lanza excepción
        when(mockLocal.saveAuthgData(
                token:  fakeToken,
                userId: fakeUserId))
            .thenAnswer((_) async {});

        // El perfil del usuario se obtiene correctamente
        when(mockRemote.getUserProfile(fakeUserId, fakeToken))
            .thenAnswer((_) async => fakeUser);

        // Act
        final result = await sut.register(
          email:    "lector@livria.com",
          password: "SecurePass123",
          username: "lector01",
          display:  "Lector de Prueba",
        );

        // Assert
        expect(result.username, equals("lector01"));
        expect(result.email,    equals("lector@livria.com"));

        // Verificar que se guardó el token localmente (credenciales seguras)
        verify(mockLocal.saveAuthgData(
          token:  fakeToken,
          userId: fakeUserId,
        )).called(1);

        // Verificar que se hizo login automático
        verify(mockRemote.signIn("lector01", "SecurePass123")).called(1);
      },
    );
  });

  // ----------------------------------------------------------------
  // AC2 – Login exitoso con credenciales válidas
  // ----------------------------------------------------------------
  group('AC2 – Autenticación de lector registrado', () {
    test(
      'login con credenciales correctas guarda token localmente '
      'y retorna el UserEntity correspondiente',
      () async {
        // Arrange
        const fakeToken  = 'jwt.token.fake';
        const fakeUserId = 1;

        when(mockRemote.signIn("lector01", "SecurePass123"))
            .thenAnswer((_) async => {
                  'token':  fakeToken,
                  'userId': fakeUserId,
                });

        when(mockLocal.saveAuthgData(
                token:  fakeToken,
                userId: fakeUserId))
            .thenAnswer((_) async {});

        when(mockRemote.getUserProfile(fakeUserId, fakeToken))
            .thenAnswer((_) async => fakeUser);

        // Act
        final result = await sut.login("lector01", "SecurePass123");

        // Assert — el usuario recibe acceso con sus datos correctos
        expect(result.id,       equals("1")); // Verificamos contra "1" como String
        expect(result.username, equals("lector01"));

        // El token fue persistido localmente para mantener sesión
        verify(mockLocal.saveAuthgData(
          token:  fakeToken,
          userId: fakeUserId,
        )).called(1);
      },
    );

    test(
      'login con credenciales incorrectas propaga la excepción del remote',
      () async {
        // Arrange
        when(mockRemote.signIn("lector01", "WrongPass!"))
            .thenThrow(Exception("Invalid credentials"));

        // Act & Assert
        expect(
          () => sut.login("lector01", "WrongPass!"),
          throwsException,
        );
      },
    );
  });
}