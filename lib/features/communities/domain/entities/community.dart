// lib/features/communities/domain/entities

// /api/v1/communities/ + id
// /api/v1/posts/community/ + communityId

class Community {
  final int id;
  final String name;
  final String description;
  final int type;
  final int ownerId;
  final String image;
  final String banner;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.ownerId,
    required this.image,
    required this.banner,
  });

  factory Community.fromJson(Map<String,dynamic> json) {

  return Community(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      ownerId: json['ownerId'],
      image: json['image'],
      banner: json['banner'],
    );
  }
}

/* ---- TYPES ----
  literature(1, 'LITERATURE'),
  nonFiction(2, 'NON-FICTION'),
  fiction(3, 'FICTION'),
  mangasComics(4, 'MANGAS & COMICS'),
  juvenile(5, 'JUVENILE'),
  children(6, 'CHILDREN'),
  ebooksAudiobooks(7, 'EBOOKS & AUDIOBOOKS'),
  general(8, 'GENERAL');
*/
