import 'dart:convert';

import 'package:flutter/material.dart';

/// Muestra la portada de un libro desde una URL (p. ej. Cloudinary) o desde
/// un `data:image/...;base64,...` legado guardado en la API.
class LivriaBookCover extends StatelessWidget {
  const LivriaBookCover({
    super.key,
    required this.cover,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorBuilder,
  });

  final String cover;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  static bool _isDataImageUri(String s) {
    final t = s.trimLeft().toLowerCase();
    return t.startsWith('data:image');
  }

  @override
  Widget build(BuildContext context) {
    if (cover.isEmpty) {
      return _emptyOrError(context);
    }

    if (_isDataImageUri(cover)) {
      final comma = cover.indexOf(',');
      if (comma < 0 || comma >= cover.length - 1) {
        return _emptyOrError(context);
      }
      try {
        final bytes = base64Decode(cover.substring(comma + 1).trim());
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: errorBuilder,
        );
      } catch (_) {
        return _emptyOrError(context);
      }
    }

    return Image.network(
      cover,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: errorBuilder,
    );
  }

  Widget _emptyOrError(BuildContext context) {
    if (errorBuilder != null) {
      return errorBuilder!(context, StateError('empty cover'), null);
    }
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(Icons.book_outlined, color: Colors.grey),
    );
  }
}
