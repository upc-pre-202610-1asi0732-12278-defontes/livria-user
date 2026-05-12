import 'package:flutter/material.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../orders/domain/entities/order.dart';

class OrderDetailSheet extends StatelessWidget {
  final Order order;

  const OrderDetailSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {

    final dateStr = "${order.date.day}/${order.date.month}/${order.date.year}";

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- HEADER DEL MODAL ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 15),
                const Text(
                  "ORDER DETAILS",
                  style: TextStyle(color: AppColors.primaryOrange, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 5),
                Text("Code: ${order.code}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.lightGrey),

          // --- LISTA DE LIBROS ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // 1. PORTADA
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.bookCover,
                          width: 50, height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(width: 50, height: 75, color: Colors.grey, child: const Icon(Icons.book)),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // DETALLES
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.bookTitle,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            // Precio unitario x Cantidad
                            Text(
                              "${item.quantity} x S/ ${item.bookPrice.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            )
                          ],
                        ),
                      ),

                      // 3. TOTAL DEL ITEM
                      Text(
                        "S/ ${item.itemTotal.toStringAsFixed(2)}",
                        style: const TextStyle(color: AppColors.vibrantBlue, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // --- DESGLOSE ---
          if (order.isDelivery && order.shippingDetails != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lightGrey)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Books subtotal", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        "S/ ${(order.total - order.shippingDetails!.price).toStringAsFixed(2)}",
                        style: const TextStyle(color: AppColors.darkBlue, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.softTeal),
                          const SizedBox(width: 4),
                          Text(
                            "Shipping (${order.shippingDetails!.district})",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        "S/ ${order.shippingDetails!.price.toStringAsFixed(2)}",
                        style: const TextStyle(color: AppColors.softTeal, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // --- FOOTER CON TOTAL ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lightGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Placed on", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("TOTAL", style: TextStyle(color: AppColors.secondaryYellow, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text("S/ ${order.total.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.darkBlue, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}