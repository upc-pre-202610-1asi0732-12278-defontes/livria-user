import 'dart:convert';

class Review {
  final int id;
  final int bookId;
  final int userId;
  final String username;
  final String? userIcon;
  final String content;
  final int stars;

  const Review({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.username,
    this.userIcon,
    required this.content,
    required this.stars
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // DEBUG: Imprimir para ver qué campos llegan realmente en la reseña
    // print('REVIEW MAP: $map');

    return Review(
      id: parseId(map['id']),
      bookId: parseId(map['bookId']),
      // Buscamos específicamente el ID del usuario. 
      // Si en tu API se llama diferente, aquí es donde debemos capturarlo.
      userId: parseId(map['userClientId'] ?? map['userId'] ?? map['idUser'] ?? map['user_id']),
      username: map['username'] ?? '',
      userIcon: map['icon'] ?? map['userIcon'],
      content: map['content'] ?? '',
      stars: parseId(map['stars']),
    );
  }

  static List<Review> listFromJson(String body) {
    final raw = json.decode(body) as List<dynamic>;
    return raw.map((e) => Review.fromMap(e as Map<String, dynamic>)).toList();
  }
}
