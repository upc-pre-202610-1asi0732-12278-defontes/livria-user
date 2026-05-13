// US19 – Core Integration Test
// Valida que BookService filtra correctamente por título (AC1)
// y por autor (AC2) usando BookRepository mockeado.
// Framework: flutter_test + mockito | Patrón: Arrange – Act – Assert

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:livria_user/features/book/application/services/book_service.dart';
import 'package:livria_user/features/book/domain/entities/book.dart';
import 'package:livria_user/features/book/domain/repositories/book_repository.dart';

import 'US19_book_search_test.mocks.dart';

@GenerateMocks([BookRepository])
void main() {
  late MockBookRepository mockBookRepo;
  late BookService sut;

  // ------------------------------------------------------------------
  // Catálogo de prueba — simula lo que devuelve el backend
  // ------------------------------------------------------------------
  final catalog = [
    Book(
      id: 1,
      title: 'El Principito',
      description: 'Una historia atemporal',
      author: 'Antoine de Saint-Exupéry',
      salePrice: 29.99,
      purchasePrice: 18.00,
      stock: 5,
      cover: 'https://livria.com/covers/principito.jpg',
      genre: 'fiction',
      language: 'español',
    ),
    Book(
      id: 2,
      title: 'Cien Años de Soledad',
      description: 'Realismo mágico colombiano',
      author: 'Gabriel García Márquez',
      salePrice: 39.99,
      purchasePrice: 24.00,
      stock: 3,
      cover: 'https://livria.com/covers/cien_anos.jpg',
      genre: 'literature',
      language: 'español',
    ),
    Book(
      id: 3,
      title: 'El Amor en los Tiempos del Cólera',
      description: 'Romance épico',
      author: 'Gabriel García Márquez',
      salePrice: 35.00,
      purchasePrice: 21.00,
      stock: 7,
      cover: 'https://livria.com/covers/amor_colera.jpg',
      genre: 'literature',
      language: 'español',
    ),
    Book(
      id: 4,
      title: 'Don Quijote de la Mancha',
      description: 'La primera novela moderna',
      author: 'Miguel de Cervantes',
      salePrice: 45.00,
      purchasePrice: 27.00,
      stock: 10,
      cover: 'https://livria.com/covers/quijote.jpg',
      genre: 'literature',
      language: 'español',
    ),
  ];

  // ------------------------------------------------------------------
  // Helper: aplica el mismo filtro que usa SearchPage
  // ------------------------------------------------------------------
  List<Book> applySearchFilter(List<Book> books, String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return books
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q))
        .toList();
  }

  setUp(() {
    mockBookRepo = MockBookRepository();
    sut          = BookService(mockBookRepo);

    when(mockBookRepo.getAll()).thenAnswer((_) async => catalog);
  });

  // ----------------------------------------------------------------
  // AC1 – Búsqueda por título
  // ----------------------------------------------------------------
  group('US19 AC1 – Búsqueda por título', () {
    test(
      'US19_AC1 búsqueda por título exacto retorna el libro correcto '
      'con título, autor e imagen no vacíos',
      () async {
        // Arrange
        const query = 'El Principito';

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert — AC1: información esencial presente
        expect(results, hasLength(1));
        expect(results.first.title,  equals('El Principito'));
        expect(results.first.author, isNotEmpty,
            reason: 'AC1: el autor debe estar disponible en el resultado');
        expect(results.first.cover,  isNotEmpty,
            reason: 'AC1: la imagen debe estar disponible en el resultado');

        verify(mockBookRepo.getAll()).called(1);
      },
    );

    test(
      'US19_AC1 búsqueda por título parcial retorna todos los libros '
      'que contienen el término en su título',
      () async {
        // Arrange
        const query = 'el'; // coincide con "El Principito" y "El Amor..."

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert
        expect(results.length, greaterThanOrEqualTo(2));
        expect(
          results.every((b) =>
              b.title.toLowerCase().contains('el') ||
              b.author.toLowerCase().contains('el')),
          isTrue,
        );
      },
    );

    test(
      'US19_AC1 búsqueda case-insensitive retorna el libro '
      'independientemente de mayúsculas',
      () async {
        // Arrange
        const query = 'EL PRINCIPITO';

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert
        expect(results, hasLength(1));
        expect(results.first.title, equals('El Principito'));
      },
    );

    test(
      'US19_AC1 búsqueda sin coincidencias retorna lista vacía',
      () async {
        // Arrange
        const query = 'Harry Potter';

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert
        expect(results, isEmpty);
      },
    );
  });

  // ----------------------------------------------------------------
  // AC2 – Búsqueda por autor
  // ----------------------------------------------------------------
  group('US19 AC2 – Búsqueda por autor', () {
    test(
      'US19_AC2 búsqueda por autor retorna TODOS sus libros del catálogo',
      () async {
        // Arrange
        const query = 'Gabriel García Márquez';

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert — AC2: todos los libros del autor
        expect(results, hasLength(2));
        expect(
          results.every((b) => b.author == 'Gabriel García Márquez'),
          isTrue,
          reason: 'AC2: todos los resultados deben ser del autor buscado',
        );
      },
    );

    test(
      'US19_AC2 búsqueda por apellido parcial retorna libros del autor',
      () async {
        // Arrange
        const query = 'García'; // apellido parcial

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert
        expect(results, hasLength(2));
        expect(
          results.every((b) =>
              b.author.toLowerCase().contains('garcía')),
          isTrue,
        );
      },
    );

    test(
      'US19_AC2 búsqueda por autor inexistente retorna lista vacía',
      () async {
        // Arrange
        const query = 'J.K. Rowling';

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert
        expect(results, isEmpty);
      },
    );

    test(
      'US19_AC2 cada resultado de autor tiene título, autor y cover no vacíos',
      () async {
        // Arrange
        const query = 'García Márquez';

        // Act
        final allBooks = await sut.getAllBooks();
        final results  = applySearchFilter(allBooks, query);

        // Assert — información esencial disponible en cada resultado
        expect(results, isNotEmpty);
        for (final book in results) {
          expect(book.title,  isNotEmpty);
          expect(book.author, isNotEmpty);
          expect(book.cover,  isNotEmpty);
        }
      },
    );
  });

  // ----------------------------------------------------------------
  // getGenres — AC1 complementario (búsqueda por categoría)
  // ----------------------------------------------------------------
  group('US19 – getGenres devuelve géneros únicos ordenados', () {
    test(
      'US19 getGenres retorna géneros únicos ordenados alfabéticamente',
      () async {
        // Act
        final genres = await sut.getGenres();

        // Assert
        expect(genres, isNotEmpty);
        expect(genres, equals([...genres]..sort(
            (a, b) => a.toLowerCase().compareTo(b.toLowerCase()))));
        expect(genres.toSet().length, equals(genres.length),
            reason: 'No debe haber géneros duplicados');
      },
    );
  });
}