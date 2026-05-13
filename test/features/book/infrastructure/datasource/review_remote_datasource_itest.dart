import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:livria_user/common/config/env.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:livria_user/features/book/infrastructure/datasource/review_remote_datasource.dart';

@GenerateMocks([http.Client, AuthLocalDataSource])
import 'review_remote_datasource_itest.mocks.dart';

void main() {
  late ReviewRemoteDataSource dataSource;
  late MockClient mockClient;
  late MockAuthLocalDataSource mockAuthDs;

  final String baseUrl = Env.apiBase;
  const String reviewsPath = '/api/v1/reviews';
  const String testToken = 'test-jwt-token';
  const int testUserId = 123;
  const int testBookId = 456;

  setUp(() {
    mockClient = MockClient();
    mockAuthDs = MockAuthLocalDataSource();
    dataSource = ReviewRemoteDataSource(
      client: mockClient,
      authDs: mockAuthDs,
    );
  });

  group('getAllReviews', () {
    final uri = Uri.parse('$baseUrl$reviewsPath');

    test('Debe devolver Response 200 si la llamada es exitosa', () async {
      when(mockClient.get(uri))
          .thenAnswer((_) async => http.Response('[]', 200));

      final result = await dataSource.getAllReviews();

      expect(result.statusCode, 200);
      verify(mockClient.get(uri)).called(1);
    });

    test('Debe devolver Response 500 si la API falla', () async {
      when(mockClient.get(uri))
          .thenAnswer((_) async => http.Response('Server Error', 500));

      final result = await dataSource.getAllReviews();

      expect(result.statusCode, 500);
    });
  });

  group('getBookReviews', () {
    final uri = Uri.parse('$baseUrl$reviewsPath/book/$testBookId');

    test('Debe devolver Response 200 con Authorization Header si hay token', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => testToken);
      when(mockClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $testToken',
        },
      )).thenAnswer((_) async => http.Response('[{"id": 1, "content": "Great"}]', 200));

      final result = await dataSource.getBookReviews(testBookId);

      expect(result.statusCode, 200);
      verify(mockAuthDs.getToken()).called(1);
      verify(mockClient.get(
        uri,
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('Debe lanzar Exception 401 si getToken devuelve null', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => null);

      expect(
            () => dataSource.getBookReviews(testBookId),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('Error 401')),
        ),
      );
      verify(mockAuthDs.getToken()).called(1);
      verifyNever(mockClient.get(any));
    });
  });

  group('postReview', () {
    final uri = Uri.parse('$baseUrl$reviewsPath');
    final Map<String, dynamic> expectedBody = {
      'bookId': testBookId,
      'userClientId': testUserId,
      'content': 'Muy buen libro',
      'stars': 5,
    };

    test('Debe devolver Response 201 si el usuario está loggeado y el post es exitoso', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => testToken);
      when(mockAuthDs.getUserId()).thenAnswer((_) async => testUserId);

      when(mockClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $testToken',
        },
        body: json.encode(expectedBody),
      )).thenAnswer((_) async => http.Response('{"id": 10}', 201));

      final result = await dataSource.postReview(
        bookId: testBookId,
        content: 'Muy buen libro',
        stars: 5,
      );

      expect(result.statusCode, 201);
      verify(mockAuthDs.getToken()).called(1);
      verify(mockAuthDs.getUserId()).called(1);
      verify(mockClient.post(
        uri,
        headers: anyNamed('headers'),
        body: json.encode(expectedBody),
      )).called(1);
    });

    test('Debe lanzar Exception 401 si falta el token o el UserId', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => testToken);
      when(mockAuthDs.getUserId()).thenAnswer((_) async => null);

      expect(
            () => dataSource.postReview(
          bookId: testBookId,
          content: 'Contenido',
          stars: 4,
        ),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('Error 401')),
        ),
      );
      verifyNever(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')));
    });
  });
}
