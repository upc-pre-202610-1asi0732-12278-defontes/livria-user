import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../common/services/analytics_service.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../application/services/payment_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/create_order_usecase.dart';

class OrderProvider extends ChangeNotifier {
  final CreateOrderUseCase createOrderUseCase;
  final PaymentService _paymentService = PaymentService();

  OrderProvider({required this.createOrderUseCase});

  // --- ESTADO DE CARGA ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- ESTADO DEL FORMULARIO ---

  // Paso 1: Recipient
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String get fullRecipientName => "${nameController.text} ${lastNameController.text}".trim();

  // Paso 2: Envío
  bool _isDelivery = true;
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();

  bool get isDelivery => _isDelivery;

  void setDelivery(bool value) {
    _isDelivery = value;
    notifyListeners();
  }

  void notifyDistrictChanged() {
    notifyListeners();
  }

  double get getShippingPrice {
    const zone1 = ['Lince', 'Pueblo Libre', 'Magdalena del Mar', 'San Miguel',
      'Breña', 'La Victoria', 'Miraflores', 'San Isidro'];
    const zone2 = ['Barranco', 'Chorrillos', 'San Borja', 'Surquillo',
      'Santiago de Surco', 'San Luis', 'Rímac', 'Independencia', 'Los Olivos',
      'San Martín de Porres', 'Ate', 'El Agustino', 'Santa Anita', 'La Molina',
      'San Juan de Miraflores'];

    final district = districtController.text;
    if (zone1.contains(district)) return 5.0;
    if (zone2.contains(district)) return 8.0;
    return 12.0;
  }

  // --- PRINCIPAL METHOD: SUBMIT CON EVIDENCIA ---

  Future<bool> submitOrderWithEvidence(BuildContext context, File evidence, double total) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. SUBIR CAPTURA A CLOUDINARY
      final imageUrl = await _paymentService.uploadToCloudinary(evidence);
      if (imageUrl == null) {
        throw Exception("Error al subir la captura de pantalla. Inténtalo de nuevo.");
      }

      final totalWithShipping = total + getShippingPrice;

      // 2. ENVIAR NOTIFICACIÓN POR CORREO (EmailJS)
      final emailSent = await _paymentService.sendEmail(
        serviceId: 'service_4t97z5d',
        templateId: 'template_kgn4xci',
        publicKey: '9sYY-fTEKMm4wPX-k',
        params: {
          'payment_type': 'ORDER PAYMENT',
          'intro_text': 'A new order has been placed and requires verification.',
          'full_name': fullRecipientName,
          'email': emailController.text,
          'phone': phoneController.text,
          'order_details': _isDelivery ? 'Home delivery: ${addressController.text}, ${districtController.text}' : 'Pick up in store',
          'user_id': '-',
          'submitted_date': '-',
          'total_amount': _isDelivery ? 'S/ $totalWithShipping' : 'S/ ${total.toStringAsFixed(2)}',
          'my_file': imageUrl,
        },
      );

      if (!emailSent) {
        throw Exception("No se pudo enviar la notificación de pago. La orden no fue procesada.");
      }

      // 3. CREAR ORDEN EN BACKEND C#
      final authDs = AuthLocalDataSource();
      final userId = await authDs.getUserId();
      if (userId == null) throw Exception("Usuario no autenticado");

      ShippingDetails? shipping;
      if (_isDelivery) {
        shipping = ShippingDetails(
          address: addressController.text,
          city: cityController.text.isEmpty ? 'Lima Metropolitana' : cityController.text,
          district: districtController.text,
          reference: referenceController.text,
          price: getShippingPrice,
        );
      }

      debugPrint('!!!!!!!!!!!!!!!!! PLEASE CHECK IF YOUR TOTAL IS GETTING CALCULATED PROPERLY');
      debugPrint('Your price is: $total');
      debugPrint('Your shipping price is: $getShippingPrice');

      await createOrderUseCase(
        userClientId: userId,
        userEmail: emailController.text,
        userPhone: phoneController.text,
        userFullName: fullRecipientName,
        recipientName: fullRecipientName,
        isDelivery: _isDelivery,
        status: "pending",
        shippingDetails: shipping,
      );

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();

      // Exp 10
      LivriaAnalytics.logEvent('app_exception', {
        'screen': 'payment_page',
        'error': e.toString().substring(0, 100),
        'fatal': false,
      });

      // Feedback visual del error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent
        ),
      );
      return false;
    }
  }

  // --- UTILITARIOS ---

  void clearForm() {
    nameController.clear();
    lastNameController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    cityController.clear();
    districtController.clear();
    referenceController.clear();
    _isDelivery = true;
    notifyListeners();
  }
}