import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/services/analytics_service.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../../cart/presentation/widgets/cart_drawer.dart';
import '../providers/order_provider.dart';
import '../widgets/checkout_progress_bar.dart';

class ShippingInfoPage extends StatelessWidget {
  const ShippingInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el provider para saber si es delivery o pick up
    final orderProvider = context.watch<OrderProvider>();
    final isDelivery = orderProvider.isDelivery;

    return Scaffold(
      backgroundColor: AppColors.white,

      // EndDrawer conectado (igual que en la pantalla anterior)
      endDrawer: FutureBuilder<int?>(
        future: AuthLocalDataSource().getUserId(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CartDrawer(userId: snapshot.data!);
          }
          return const Drawer(child: Center(child: CircularProgressIndicator()));
        },
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER
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

                // Botón View Items
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softTeal,
                      foregroundColor: AppColors.darkBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("VIEW ITEMS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 25),

                // 2. PROGRESS BAR (Paso 2: Shipping activo)
                const Center(child: CheckoutProgressBar(currentStep: 2)),

                const SizedBox(height: 25),

                // 3. TARJETA PRINCIPAL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "DELIVERY INFORMATION",
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.vibrantBlue),
                        ),
                        child: Row(
                          children: [
                            _buildToggleButton(
                                context,
                                label: "PICK UP IN STORE",
                                isActive: !isDelivery,
                                onTap: () => orderProvider.setDelivery(false)
                            ),
                            _buildToggleButton(
                                context,
                                label: "HOME DELIVERY",
                                isActive: isDelivery,
                                onTap: () => orderProvider.setDelivery(true)
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (!isDelivery)
                        _buildPickUpContent(context)
                      else
                        _buildDeliveryForm(orderProvider),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 4. BOTONES DE NAVEGACIÓN (Back / Continue)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón BACK
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text("BACK", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkBlue,
                      ),
                    ),

                    // Botón CONTINUE
                    ElevatedButton(
                      onPressed: () {
                        // VALIDACIÓN
                        if (orderProvider.isDelivery) {
                          if (orderProvider.addressController.text.isEmpty ||
                              orderProvider.districtController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please fill in all fields"),
                                  backgroundColor: AppColors.errorRed,
                                )
                            );
                            return;
                          }
                        }

                        LivriaAnalytics.logEvent('add_shipping_info', {
                          'shipping_tier': orderProvider.isDelivery ? 'home_delivery' : 'pick_up',
                        });

                        context.push('/checkout/payment');
                        debugPrint("Ir a Pago ->");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softTeal,
                        foregroundColor: AppColors.darkBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildToggleButton(BuildContext context, {required String label, required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.softTeal : AppColors.white,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkBlue,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickUpContent(BuildContext context) {
    return Column(
      children: [
        const Text(
          "You can come to the store to pick up your order starting 3 business days after your order confirmation.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.darkBlue, height: 1.5),
        ),
        const SizedBox(height: 20),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: AppColors.darkBlue, fontSize: 14),
            children: [
              const TextSpan(text: "For more details about our store, click "),
              TextSpan(
                text: "here.",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.push('/location'); // Navegar a ubicación
                  },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryForm(OrderProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("City"),
        Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: TextFormField(
            initialValue: 'Lima Metropolitana',
            enabled: false,
            style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.lightGrey,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel("District"),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: DropdownButtonFormField<String>(
            value: provider.districtController.text.isEmpty ? null : provider.districtController.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
              ),
            ),
            hint: const Text('Select district'),
            items: _limaDistricts.map((district) => DropdownMenuItem(
              value: district,
              child: Text(district),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                provider.districtController.text = value;
                provider.notifyDistrictChanged();
              }
            },
          ),
        ),
        if (provider.districtController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.softTeal),
                const SizedBox(width: 6),
                Text(
                  'Shipping cost: S/ ${_getShippingPrice(provider.districtController.text).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _buildLabel("Address"),
        _buildInput(controller: provider.addressController),
        const SizedBox(height: 16),

        _buildLabel("Reference (Optional)"),
        _buildInput(controller: provider.referenceController),
      ],
    );
  }

  // Reutilizamos el estilo de input de la pantalla anterior
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ]
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          ),
        ),
      ),
    );
  }
}

const List<String> _limaDistricts = [
  'Ancón', 'Ate', 'Barranco', 'Breña', 'Carabayllo', 'Chaclacayo',
  'Chorrillos', 'Cieneguilla', 'Comas', 'El Agustino', 'Independencia',
  'Jesús María', 'La Molina', 'La Victoria', 'Lima', 'Lince',
  'Los Olivos', 'Lurigancho', 'Lurín', 'Magdalena del Mar', 'Miraflores',
  'Pachacámac', 'Pucusana', 'Pueblo Libre', 'Puente Piedra', 'Punta Hermosa',
  'Punta Negra', 'Rímac', 'San Bartolo', 'San Borja', 'San Isidro',
  'San Juan de Lurigancho', 'San Juan de Miraflores', 'San Luis',
  'San Martín de Porres', 'San Miguel', 'Santa Anita', 'Santa María del Mar',
  'Santa Rosa', 'Santiago de Surco', 'Surquillo', 'Villa El Salvador',
  'Villa María del Triunfo',
];

double _getShippingPrice(String district) {
  const zone1 = ['Lince', 'Pueblo Libre', 'Magdalena del Mar', 'San Miguel',
    'Breña', 'La Victoria', 'Miraflores', 'San Isidro'];
  const zone2 = ['Barranco', 'Chorrillos', 'San Borja', 'Surquillo',
    'Santiago de Surco', 'San Luis', 'Rímac', 'Independencia', 'Los Olivos',
    'San Martín de Porres', 'Ate', 'El Agustino', 'Santa Anita', 'La Molina',
    'San Juan de Miraflores'];

  if (zone1.contains(district)) return 5.0;
  if (zone2.contains(district)) return 8.0;
  return 12.0;
}