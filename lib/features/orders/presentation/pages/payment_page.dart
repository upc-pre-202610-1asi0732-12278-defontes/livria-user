import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../providers/order_provider.dart';
import '../widgets/checkout_progress_bar.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _evidenceImage;
  final ImagePicker _picker = ImagePicker();
  final String _cci = "002191103718905053";

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) {
      setState(() {
        _evidenceImage = File(selected.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SUBMIT ORDER",
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                const Center(child: CheckoutProgressBar(currentStep: 3)),
                const SizedBox(height: 30),

                // SECCIÓN DE TRANSFERENCIA
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "BANK TRANSFER",
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Please transfer the total amount to the following CCI and upload the screenshot.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.darkBlue, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // CCI DISPLAY
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _cci));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("CCI copied to clipboard")),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.softTeal),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _cci,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.copy, size: 18, color: AppColors.softTeal),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // IMAGE UPLOAD AREA
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _evidenceImage == null ? Colors.grey.shade300 : AppColors.softTeal,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _evidenceImage == null
                              ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Upload Transfer Screenshot", style: TextStyle(color: Colors.grey)),
                            ],
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_evidenceImage!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // BOTONES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text("BACK", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
                    ),
                    ElevatedButton(
                      onPressed: (orderProvider.isLoading || _evidenceImage == null)
                          ? null
                          : () => _handleSubmit(context, orderProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softTeal,
                        foregroundColor: AppColors.darkBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: orderProvider.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("CONFIRM ORDER", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, OrderProvider provider) async {
    const double totalAmount = 85.50; // Reemplaza esto por tu variable real

    // Ahora pasamos los 3 argumentos: context, imagen y el monto
    final success = await provider.submitOrderWithEvidence(
        context,
        _evidenceImage!,
        totalAmount
    );

    if (success && context.mounted) {
      provider.clearForm();
      context.go('/checkout/confirmation');
    }
  }
}