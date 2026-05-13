// US20 – Core Integration Test (versión sin build_runner)
// CreateOrderUseCase y PaymentService son clases concretas —
// mockito no puede auto-generarlas. Usamos mocks manuales con Fake.
// Framework: flutter_test | Patrón: Arrange – Act – Assert
 
import 'package:flutter_test/flutter_test.dart';
 
import 'package:livria_user/features/orders/domain/entities/order.dart';
import 'package:livria_user/features/orders/domain/repositories/order_repository.dart';
import 'package:livria_user/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:livria_user/features/orders/presentation/providers/order_provider.dart';
 
// ------------------------------------------------------------------
// Mock manual de OrderRepository
// ------------------------------------------------------------------
class FakeOrderRepository implements OrderRepository {
  Order? lastCreatedOrder;
  bool shouldThrow = false;
 
  @override
  Future<Order> createOrder({
    required int userClientId,
    required String userEmail,
    required String userPhone,
    required String userFullName,
    required String recipientName,
    required bool isDelivery,
    required String status,
    ShippingDetails? shippingDetails,
  }) async {
    if (shouldThrow) throw Exception("Error de red simulado");
 
    lastCreatedOrder = Order(
      id:              1,
      code:            "ABC123",
      total:           29.99 + (isDelivery ? 5.0 : 0),
      status:          status,
      isDelivery:      isDelivery,
      date:            DateTime.utc(2026, 5, 12),
      shippingDetails: shippingDetails,
      items:           [],
      userEmail:       userEmail,
      userFullName:    userFullName,
      userPhone:       userPhone,
    );
    return lastCreatedOrder!;
  }
 
  @override
  Future<List<Order>> getOrdersByUser(int userId) async => [];
}
 
void main() {
  late FakeOrderRepository fakeRepo;
  late CreateOrderUseCase  createOrderUseCase;
  late OrderProvider       sut;
 
  setUp(() {
    fakeRepo           = FakeOrderRepository();
    createOrderUseCase = CreateOrderUseCase(fakeRepo);
    sut                = OrderProvider(createOrderUseCase: createOrderUseCase);
 
    sut.nameController.text     = "Lector";
    sut.lastNameController.text = "Prueba";
    sut.phoneController.text    = "999888777";
    sut.emailController.text    = "lector@livria.com";
    sut.districtController.text = "Miraflores";
  });
 
  // ----------------------------------------------------------------
  // AC1 – CCI disponible para la transferencia
  // ----------------------------------------------------------------
  group('US20 AC1 – Número de cuenta interbancaria', () {
    test(
      'US20_AC1 el CCI tiene formato correcto (18 dígitos numéricos)',
      () {
        const cci = "002191103718905053";
 
        expect(cci, isNotEmpty);
        expect(cci.length, equals(18),
            reason: 'El CCI peruano tiene exactamente 18 dígitos');
        expect(RegExp(r'^\d+$').hasMatch(cci), isTrue,
            reason: 'El CCI debe ser completamente numérico');
      },
    );
 
    test(
      'US20_AC1 precio de envío zona 1 (Miraflores) es S/5.0',
      () {
        sut.districtController.text = "Miraflores";
        expect(sut.getShippingPrice, equals(5.0));
      },
    );
 
    test(
      'US20_AC1 precio de envío zona 2 (Barranco) es S/8.0',
      () {
        sut.districtController.text = "Barranco";
        expect(sut.getShippingPrice, equals(8.0));
      },
    );
 
    test(
      'US20_AC1 precio de envío zona 3 (Comas) es S/12.0',
      () {
        sut.districtController.text = "Comas";
        expect(sut.getShippingPrice, equals(12.0));
      },
    );
 
    test(
      'US20_AC1 total con delivery incluye costo de envío',
      () {
        sut.setDelivery(true);
        sut.districtController.text = "Miraflores";
        const subtotal = 29.99;
 
        final total = subtotal + sut.getShippingPrice;
 
        // closeTo porque double IEEE 754: 29.99 + 5.0 != 34.99 exacto
        expect(total, closeTo(34.99, 0.001));
      },
    );
 
    test(
      'US20_AC1 total sin delivery es solo el subtotal',
      () {
        sut.setDelivery(false);
        const subtotal = 29.99;
 
        final total = subtotal + (sut.isDelivery ? sut.getShippingPrice : 0);
 
        expect(total, equals(29.99));
      },
    );
  });
 
  // ----------------------------------------------------------------
  // AC2 – Comprobante registrado, orden en "pending"
  // ----------------------------------------------------------------
  group('US20 AC2 – Registro de comprobante y estado pending', () {
    test(
      'US20_AC2 fullRecipientName combina nombre y apellido',
      () {
        sut.nameController.text     = "Lector";
        sut.lastNameController.text = "Prueba";
 
        expect(sut.fullRecipientName, equals("Lector Prueba"));
      },
    );
 
    test(
      'US20_AC2 fullRecipientName sin apellido no deja espacios extra',
      () {
        sut.nameController.text     = "Lector";
        sut.lastNameController.text = "";
 
        expect(sut.fullRecipientName, equals("Lector"));
      },
    );
 
    test(
      'US20_AC2 isLoading inicia en false — '
      'provider listo para recibir el comprobante',
      () {
        expect(sut.isLoading, isFalse);
      },
    );
 
    test(
      'US20_AC2 clearForm limpia todos los campos tras confirmar la orden',
      () {
        sut.nameController.text     = "Lector";
        sut.phoneController.text    = "999888777";
        sut.districtController.text = "Miraflores";
 
        sut.clearForm();
 
        expect(sut.nameController.text,     isEmpty);
        expect(sut.phoneController.text,    isEmpty);
        expect(sut.districtController.text, isEmpty);
        expect(sut.isDelivery, isTrue,
            reason: 'isDelivery vuelve a true por defecto tras limpiar');
      },
    );
 
    test(
      'US20_AC2 setDelivery cambia el modo de envío correctamente',
      () {
        sut.setDelivery(false);
        expect(sut.isDelivery, isFalse);
 
        sut.setDelivery(true);
        expect(sut.isDelivery, isTrue);
      },
    );
 
    test(
      'US20_AC2 total zona 2 con delivery incluye S/8.0 de envío',
      () {
        sut.setDelivery(true);
        sut.districtController.text = "La Molina"; // zona 2
        const subtotal = 59.98;
 
        final total = subtotal + sut.getShippingPrice;
 
        // closeTo porque double IEEE 754: 59.98 + 8.0 != 67.98 exacto
        expect(total, closeTo(67.98, 0.001));
      },
    );
 
    test(
      'US20_AC2 CreateOrderUseCase con FakeRepo crea orden en estado pending',
      () async {
        final result = await createOrderUseCase(
          userClientId:  1,
          userEmail:     "lector@livria.com",
          userPhone:     "999888777",
          userFullName:  "Lector Prueba",
          recipientName: "Lector Prueba",
          isDelivery:    false,
          status:        "pending",
        );
 
        expect(result.status, equals("pending"),
            reason: 'AC2: la orden debe mantenerse en estado pending '
                'hasta que el admin valide el comprobante');
        expect(result.code,  isNotEmpty);
        expect(result.total, greaterThan(0));
 
        expect(fakeRepo.lastCreatedOrder,        isNotNull);
        expect(fakeRepo.lastCreatedOrder!.status, equals("pending"));
      },
    );
 
    test(
      'US20_AC2 CreateOrderUseCase con delivery incluye shipping en la orden',
      () async {
        final shipping = ShippingDetails(
          address:   "Av. Larco 123",
          city:      "Lima",
          district:  "Miraflores",
          reference: "Ref: parque",
          price:     5.0,
        );
 
        final result = await createOrderUseCase(
          userClientId:    1,
          userEmail:       "lector@livria.com",
          userPhone:       "999888777",
          userFullName:    "Lector Prueba",
          recipientName:   "Lector Prueba",
          isDelivery:      true,
          status:          "pending",
          shippingDetails: shipping,
        );
 
        expect(result.isDelivery,                isTrue);
        expect(result.shippingDetails,           isNotNull);
        expect(result.shippingDetails!.district, equals("Miraflores"));
        expect(result.total, greaterThan(29.99),
            reason: 'El total debe incluir el costo de envío');
      },
    );
  });
}