import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/theme/app_colors.dart';
import '../../domain/entities/book.dart';

class HorizontalBookCard extends StatelessWidget {
  final Book b;
  final TextTheme t;

  static const double standardHeight = 120.0;

  const HorizontalBookCard(this.b, this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: standardHeight,
      child: Material(
        elevation: 3,
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final bookId = Uri.encodeComponent(b.id.toString());
            GoRouter.of(context).go('/book/$bookId');
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Portada a la izquierda
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 3.5 / 6,
                    child: Image.network(
                      b.cover,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) =>
                          Container(
                            color: AppColors.lightGrey,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported),
                          ),
                    ),
                  ),
                ),
      
                const SizedBox(width: 10),
      
                // Texto a la derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        b.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      // Autor
                      Text(
                        b.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          color: AppColors.vibrantBlue,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      // Precio al fondo
                      Text(
                        'S/ ${b.salePrice.toStringAsFixed(2)}',
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.darkBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}