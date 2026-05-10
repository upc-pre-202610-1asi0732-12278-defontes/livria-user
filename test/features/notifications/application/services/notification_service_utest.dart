import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:livria_user/features/notifications/domain/entities/notification.dart';
import 'package:livria_user/features/notifications/domain/repositories/notification_repository.dart';
import 'package:livria_user/features/notifications/application/services/notification_service.dart';

@GenerateMocks([NotificationRepository])
import 'notification_service_utest.mocks.dart';

void main() {
  late NotificationService service;
  late MockNotificationRepository mockRepository;

  final mockNotifications = [
    Notification(
      id: 1,
      userClientId: 10,
      createdAt: DateTime(2025, 12, 1, 10, 0),
      type: 1,
      title: 'Oferta',
      content: 'Nuevo libro disponible',
      isRead: false,
      isHidden: false,
    ),
    Notification(
      id: 2,
      userClientId: 10,
      createdAt: DateTime(2025, 12, 1, 11, 0),
      type: 2,
      title: 'Aviso',
      content: 'Tu pedido ha sido enviado',
      isRead: true,
      isHidden: false,
    ),
  ];

  setUp(() {
    mockRepository = MockNotificationRepository();
    service = NotificationService(mockRepository);
  });

  group('NotificationService Tests', () {
    test('getNotifications debe devolver la lista del repositorio', () async {
      when(mockRepository.getAllNotifications())
          .thenAnswer((_) async => mockNotifications);

      final result = await service.getNotifications();

      expect(result, mockNotifications);
      expect(result.length, 2);
      verify(mockRepository.getAllNotifications()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('hideAllNotifications debe llamar al repositorio', () async {
      when(mockRepository.hideAllNotifications()).thenAnswer((_) async {});

      await service.hideAllNotifications();

      verify(mockRepository.hideAllNotifications()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
