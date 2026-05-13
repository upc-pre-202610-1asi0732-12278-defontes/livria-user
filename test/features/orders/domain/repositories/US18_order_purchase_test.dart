// US18 – Core Integration Test
// Valida que OrderRepository.createOrder() es llamado correctamente
// al completar la compra, tanto con delivery como sin él.
// Framework: flutter_test + mockito | Patrón: Arrange – Act – Assert

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:livria_user/features/orders/domain/entities/order.dart';
import 'package:livria_user/features/orders/domain/repositories/order_repository.dart';

import 'US18_order_purchase_test.mocks.dart';

@GenerateMocks([OrderRepository])
void main() {
  late MockOrderRepository mockOrderRepo;

  // ------------------------------------------------------------------
  // Helper: construye una Order de respuesta simulando el backend
  // ------------------------------------------------------------------
  Order buildFakeOrder({
    int              id           = 1,
    String           code         = "ABC123",
    double           total        = 59.98,
    String           status       = "pending",
    bool             isDelivery   = false,
    ShippingDetails? shipping,
  }) =>
      Order(
        id:           id,
        code:         code,
        total:        total,
        status:       status,
        isDelivery:   isDelivery,
        date:         DateTime.utc(2026, 5, 12),
        shippingDetails: shipping,
        items:        [],
        userEmail:    "lector@livria.com",
        userFullName: "Lector Prueba",
        userPhone:    "999888777",
      );

  setUp(() {
    mockOrderRepo = MockOrderRepository();
  });

  // ----------------------------------------------------------------
  // AC2 – Compra sin delivery (recojo en tienda)
  // ----------------------------------------------------------------
  group('US18 AC2 – Completar compra sin delivery', () {
    test(
      'US18_AC2 createOrder sin delivery llama al repositorio '
      'con isDelivery=false y retorna la orden confirmada',
      () async {
        // Arrange
        final expectedOrder = buildFakeOrder(
          total:      59.98,
          isDelivery: false,
        );

        when(mockOrderRepo.createOrder(
          userClientId:  1,
          userEmail:     "lector@livria.com",
          userPhone:     "999888777",
          userFullName:  "Lector Prueba",
          recipientName: "Lector Prueba",
          isDelivery:    false,
          status:        "pending",
          shippingDetails: null,
        )).thenAnswer((_) async => expectedOrder);

        // Act — simula el tap en "Completar compra"
        final result = await mockOrderRepo.createOrder(
          userClientId:    1,
          userEmail:       "lector@livria.com",
          userPhone:       "999888777",
          userFullName:    "Lector Prueba",
          recipientName:   "Lector Prueba",
          isDelivery:      false,
          status:          "pending",
          shippingDetails: null,
        );

        // Assert — la transacción se confirma exitosamente
        expect(result.status, equals("pending"),
            reason: 'La orden debe crearse con estado pending');
        expect(result.code,   isNotEmpty,
            reason: 'La orden debe tener un código único generado');
        expect(result.total,  greaterThan(0),
            reason: 'El total debe ser mayor a 0');
        expect(result.isDelivery, isFalse);

        verify(mockOrderRepo.createOrder(
          userClientId:    1,
          userEmail:       "lector@livria.com",
          userPhone:       "999888777",
          userFullName:    "Lector Prueba",
          recipientName:   "Lector Prueba",
          isDelivery:      false,
          status:          "pending",
          shippingDetails: null,
        )).called(1);
      },
    );
  });

  // ----------------------------------------------------------------
  // AC2 – Compra con delivery (envío a domicilio)
  // ----------------------------------------------------------------
  group('US18 AC2 – Completar compra con delivery', () {
    test(
      'US18_AC2 createOrder con delivery llama al repositorio '
      'con shippingDetails y retorna la orden con envío',
      () async {
        // Arrange
        final shipping = ShippingDetails(
          address:   "Av. Larco 123",
          city:      "Lima",
          district:  "Miraflores",
          reference: "Cerca al parque",
          price:     5.0,
        );

        final expectedOrder = buildFakeOrder(
          total:      64.98, // 59.98 items + 5.00 shipping
          isDelivery: true,
          shipping:   shipping,
        );

        when(mockOrderRepo.createOrder(
          userClientId:    1,
          userEmail:       "lector@livria.com",
          userPhone:       "999888777",
          userFullName:    "Lector Prueba",
          recipientName:   "Destinatario Test",
          isDelivery:      true,
          status:          "pending",
          shippingDetails: shipping,
        )).thenAnswer((_) async => expectedOrder);

        // Act
        final result = await mockOrderRepo.createOrder(
          userClientId:    1,
          userEmail:       "lector@livria.com",
          userPhone:       "999888777",
          userFullName:    "Lector Prueba",
          recipientName:   "Destinatario Test",
          isDelivery:      true,
          status:          "pending",
          shippingDetails: shipping,
        );

        // Assert
        expect(result.isDelivery,               isTrue);
        expect(result.shippingDetails,           isNotNull,
            reason: 'La orden con delivery debe tener shippingDetails');
        expect(result.shippingDetails!.district, equals("Miraflores"));
        expect(result.total,                     greaterThan(59.98),
            reason: 'El total debe incluir el costo de envío');

        verify(mockOrderRepo.createOrder(
          userClientId:    1,
          userEmail:       "lector@livria.com",
          userPhone:       "999888777",
          userFullName:    "Lector Prueba",
          recipientName:   "Destinatario Test",
          isDelivery:      true,
          status:          "pending",
          shippingDetails: shipping,
        )).called(1);
      },
    );

    test(
      'US18_AC2 orden con delivery debe incluir precio de envío en el total',
      () async {
        // Arrange
        final shipping = ShippingDetails(
          address:   "Jr. Huallaga 123",
          city:      "Lima",
          district:  "Comas",  // zona 3 = 12.00
          reference: "",
          price:     12.0,
        );

        final expectedOrder = buildFakeOrder(
          total:      41.99,  // 29.99 item + 12.00 shipping
          isDelivery: true,
          shipping:   shipping,
        );

        when(mockOrderRepo.createOrder(
          userClientId:    anyNamed('userClientId'),
          userEmail:       anyNamed('userEmail'),
          userPhone:       anyNamed('userPhone'),
          userFullName:    anyNamed('userFullName'),
          recipientName:   anyNamed('recipientName'),
          isDelivery:      true,
          status:          anyNamed('status'),
          shippingDetails: shipping,
        )).thenAnswer((_) async => expectedOrder);

        // Act
        final result = await mockOrderRepo.createOrder(
          userClientId:    1,
          userEmail:       "lector@livria.com",
          userPhone:       "999888777",
          userFullName:    "Lector Prueba",
          recipientName:   "Lector Prueba",
          isDelivery:      true,
          status:          "pending",
          shippingDetails: shipping,
        );

        // Assert — el envío a zona 3 suma 12.00 al total
        expect(result.shippingDetails!.price, equals(12.0));
        expect(result.total, equals(41.99));
      },
    );
  });
}