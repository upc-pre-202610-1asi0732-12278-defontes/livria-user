import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:livria_user/common/config/env.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:livria_user/features/notifications/infrastructure/datasource/notification_remote_datasource.dart';

@GenerateMocks([http.Client, AuthLocalDataSource])
import 'notification_remote_datasource_itest.mocks.dart';

void main() {
  late NotificationRemoteDataSource dataSource;
  late MockClient mockClient;
  late MockAuthLocalDataSource mockAuthDs;

  final String baseUrl = Env.apiBase;
  const String notificationsPath = '/api/v1/notifications/user';
  const String hideAllPath = '/api/v1/notifications/hide-all';
  const String testToken = 'valid-notif-token';
  const int testUserId = 808;

  final Map<String, String> authenticatedHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $testToken',
  };

  setUp(() {
    mockClient = MockClient();
    mockAuthDs = MockAuthLocalDataSource();
    dataSource = NotificationRemoteDataSource(
      client: mockClient,
      authDs: mockAuthDs,
    );
    when(mockAuthDs.getToken()).thenAnswer((_) async => testToken);
  });

  group('Authentication Flow (Headers)', () {
    test('Debe lanzar Exception 401 si no se encuentra el token', () async {
      when(mockAuthDs.getToken()).thenAnswer((_) async => null);

      expect(
            () => dataSource.getAllNotifications(testUserId),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('Error 401')),
        ),
      );

      verify(mockAuthDs.getToken()).called(1);
      verifyNever(mockClient.get(any, headers: anyNamed('headers')));
    });
  });

  group('getAllNotifications', () {
    final uri = Uri.parse('$baseUrl$notificationsPath/$testUserId');

    test('Debe devolver Response 200 con el Header de Autorización', () async {
      when(mockClient.get(
        uri,
        headers: authenticatedHeaders,
      )).thenAnswer((_) async => http.Response('[]', 200));

      final result = await dataSource.getAllNotifications(testUserId);

      expect(result.statusCode, 200);
      verify(mockAuthDs.getToken()).called(1);
      verify(mockClient.get(
        uri,
        headers: authenticatedHeaders,
      )).called(1);
    });

    test('Debe devolver Response 500 si la API falla', () async {
      when(mockClient.get(
        uri,
        headers: authenticatedHeaders,
      )).thenAnswer((_) async => http.Response('Server error', 500));

      final result = await dataSource.getAllNotifications(testUserId);

      expect(result.statusCode, 500);
    });
  });

  group('hideAllNotifications', () {
    final uri = Uri.parse('$baseUrl$hideAllPath');
    final expectedBodyJson = jsonEncode({
      "userClientId": testUserId,
    });

    test('Debe hacer un PATCH con body y headers correctos', () async {
      when(mockClient.patch(
        uri,
        headers: authenticatedHeaders,
        body: expectedBodyJson,
      )).thenAnswer((_) async => http.Response('', 204));

      await dataSource.hideAllNotifications(testUserId);

      verify(mockAuthDs.getToken()).called(1);
      verify(mockClient.patch(
        uri,
        headers: authenticatedHeaders,
        body: expectedBodyJson,
      )).called(1);
    });
  });
}
