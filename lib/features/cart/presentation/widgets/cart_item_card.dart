import 'package:flutter/material.dart';
import 'package:livria_user/common/widgets/livria_book_cover.dart';
import '../../domain/entities/cart_item.dart';
import '../../../../common/theme/app_colors.dart';


class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEN DEL LIBRO
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LivriaBookCover(
              cover: item.book.cover,
              width: 70,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                width: 70, height: 100, color: Colors.grey[300],
                child: const Icon(Icons.book),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // INFO DEL LIBRO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.book.author,
                  style: const TextStyle(color: AppColors.black, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  "S/ ${item.book.salePrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),

          // CONTROLES (Dropdown y Basura)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dropdown Cantidad
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: item.quantity,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.accentGold),
                  underline: const SizedBox(),
                  items: List.generate(10, (index) => index + 1)
                      .map((val) => DropdownMenuItem(
                    value: val,
                    child: Text("$val", style: const TextStyle(fontSize: 14)),
                  ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) onQuantityChanged(val);
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Botón Eliminar
              InkWell(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline, color: AppColors.vibrantBlue, size: 28),
              ),
            ],
          )
        ],
      ),
    );
  }
}