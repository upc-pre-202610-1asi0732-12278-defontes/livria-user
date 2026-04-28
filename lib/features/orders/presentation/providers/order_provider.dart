import 'dart:io';
import 'package:flutter/material.dart';
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

  // --- MÉTODO PRINCIPAL: SUBMIT CON EVIDENCIA ---

  Future<bool> submitOrderWithEvidence(BuildContext context, File evidence, double total) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. SUBIR CAPTURA A CLOUDINARY
      // Sin esto no hay URL para el correo, así que es crítico.
      final imageUrl = await _paymentService.uploadToCloudinary(evidence);
      if (imageUrl == null) {
        throw Exception("Error al subir la captura de pantalla. Inténtalo de nuevo.");
      }

      // 2. ENVIAR NOTIFICACIÓN POR CORREO (EmailJS - Opción A)
      // Como pediste, si esto falla, NO se crea la orden en el backend.
      final emailSent = await _paymentService.sendEmail(
        serviceId: 'service_4t97z5d',
        templateId: 'template_kgn4xci',
        publicKey: '9sYY-fTEKMm4wPX-k',
        params: {
          'full_name': fullRecipientName,
          'email': emailController.text,
          'phone': phoneController.text,
          'total_amount': 'S/ ${total.toStringAsFixed(2)}',
          'order_details': _isDelivery
              ? 'Envío a domicilio: ${addressController.text}, ${districtController.text}'
              : 'Recojo en tienda',
          'my_file': imageUrl,
        },
      );

      if (!emailSent) {
        throw Exception("No se pudo enviar la notificación de pago. La orden no fue procesada.");
      }

      // 3. CREAR ORDEN EN BACKEND C#
      // Solo llegamos aquí si el correo se envió correctamente.
      final authDs = AuthLocalDataSource();
      final userId = await authDs.getUserId();
      if (userId == null) throw Exception("Usuario no autenticado");

      ShippingDetails? shipping;
      if (_isDelivery) {
        shipping = ShippingDetails(
          address: addressController.text,
          city: cityController.text,
          district: districtController.text,
          reference: referenceController.text,
        );
      }

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