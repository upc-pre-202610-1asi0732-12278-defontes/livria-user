import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:livria_user/common/config/env.dart';

import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:livria_user/features/book/infrastructure/datasource/recommendation_remote_datasource.dart';

@GenerateMocks([http.Client, AuthLocalDataSource])
import 'recommendation_remote_datasource_itest.mocks.dart';

void main() {
  late RecommendationRemoteDataSource dataSource;
  late MockClient mockClient;
  late MockAuthLocalDataSource mockAuthDs;

  final String baseUrl = Env.apiBase;
  const String recommendationsPath = '/api/v1/recommendations/users';
  const String testToken = 'valid-recommendation-token';
  const int testUserId = 999;

  final Map<String, String> authenticatedHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $testToken',
  };

  setUp(() {
    mockClient = MockClient();
    mockAuthDs = MockAuthLocalDataSource();
    dataSource = RecommendationRemoteDataSource(
      client: mockClient,
      authDs: mockAuthDs,
    );
  });

  group('getRecommendedBooks', () {
    final uri = Uri.parse('$baseUrl$recommendationsPath/$testUserId');

    test('Debe devolver Response 200 con el Header de Autorización si hay token', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => testToken);

      when(mockClient.get(
        uri,
        headers: authenticatedHeaders,
      )).thenAnswer((_) async => http.Response('[]', 200));

      final result = await dataSource.getRecommendedBooks(testUserId);

      expect(result.statusCode, 200);
      verify(mockAuthDs.getToken()).called(1);
      verify(mockClient.get(
        uri,
        headers: authenticatedHeaders,
      )).called(1);
    });

    test('Debe lanzar una excepción 401 si no se encuentra el token', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => null);

      expect(
            () => dataSource.getRecommendedBooks(testUserId),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('Error 401')),
        ),
      );

      verify(mockAuthDs.getToken()).called(1);
      verifyNever(mockClient.get(any, headers: anyNamed('headers')));
    });

    test('Debe devolver Response 500 si la API falla a pesar del token válido', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => testToken);

      when(mockClient.get(
        uri,
        headers: authenticatedHeaders,
      )).thenAnswer((_) async => http.Response('Server error', 500));

      final result = await dataSource.getRecommendedBooks(testUserId);

      expect(result.statusCode, 500);
      verify(mockAuthDs.getToken()).called(1);
      verify(mockClient.get(
        uri,
        headers: authenticatedHeaders,
      )).called(1);
    });
  });
}
