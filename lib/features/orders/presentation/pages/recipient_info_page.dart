import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/services/analytics_service.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../cart/presentation/widgets/cart_drawer.dart';
import '../providers/order_provider.dart';
import '../widgets/checkout_progress_bar.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';

class RecipientInfoPage extends StatefulWidget {
  const RecipientInfoPage({super.key});
  @override
  State<RecipientInfoPage> createState() => _RecipientInfoPageState();
}

class _RecipientInfoPageState extends State<RecipientInfoPage> {
  @override
  void initState() {
    super.initState();
    LivriaAnalytics.logEvent('begin_checkout', null);
  }

  @override
  Widget build(BuildContext context) {

    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      endDrawer: FutureBuilder<int?>(
        future: AuthLocalDataSource().getUserId(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CartDrawer(userId: snapshot.data!);
          }
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TÍTULO
                const Text(
                  "SUBMIT ORDER",
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                // 2. BOTÓN "VIEW ITEMS"
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {

                      Scaffold.of(context).openEndDrawer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softTeal,
                      foregroundColor: AppColors.darkBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "VIEW ITEMS",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 3. BARRA DE PROGRESO (Paso 1: User activo)
                const Center(child: CheckoutProgressBar(currentStep: 1)),

                const SizedBox(height: 25),

                // 4. TARJETA DE FORMULARIO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título del Formulario
                      const Center(
                        child: Text(
                          "RECIPIENT INFORMATION",
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input: Name
                      _buildLabel("Name"),
                      _buildInput(controller: orderProvider.nameController),
                      const SizedBox(height: 16),

                      // Input: Last Name
                      _buildLabel("Last Name"),
                      _buildInput(controller: orderProvider.lastNameController),
                      const SizedBox(height: 16),

                      // Input: Phone
                      _buildLabel("Phone Number"),
                      _buildInput(
                        controller: orderProvider.phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Input: Email (Read Only / Estilo diferente)
                      _buildLabel("Email"),
                      _buildInput(
                        controller: orderProvider.emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 5. BOTÓN CONTINUE
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = orderProvider.nameController.text.trim();
                      final lastName = orderProvider.lastNameController.text.trim();
                      final phone = orderProvider.phoneController.text.trim();
                      final email = orderProvider.emailController.text.trim();
                      // Validar campos básicos
                      if (orderProvider.nameController.text.isEmpty ||
                          orderProvider.lastNameController.text.isEmpty ||
                          orderProvider.phoneController.text.isEmpty ||
                          orderProvider.emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields"))
                        );
                        return;
                      }
                      final phoneRegex = RegExp(r'^[0-9]{9}$');

                      if (!phoneRegex.hasMatch(phone)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Phone number must be exactly 9 digits"),
                              backgroundColor: AppColors.errorRed,
                            )
                        );
                        return;
                      }

                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

                      if (!emailRegex.hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter a valid email address"),
                              backgroundColor: AppColors.errorRed,
                            )
                        );
                        return;
                      }

                      context.push('/checkout/shipping');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softTeal,
                      foregroundColor: AppColors.darkBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "CONTINUE",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.darkBlue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInput({
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
    Color backgroundColor = AppColors.white,
    Color textColor = AppColors.black,
    TextInputType keyboardType = TextInputType.text,
  }) {

    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            if (!readOnly)
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2)
              )
          ]
      ),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none, // Sin borde visible
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5), // Borde naranja al enfocar
          ),
        ),
      ),
    );
  }
}