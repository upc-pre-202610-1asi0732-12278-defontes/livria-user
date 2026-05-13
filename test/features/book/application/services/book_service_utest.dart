// US 12 TEST

import 'package:flutter_test/flutter_test.dart';

import 'package:livria_user/features/book/domain/entities/book.dart';
import 'package:livria_user/features/book/domain/repositories/book_repository.dart';
import 'package:livria_user/features/book/application/services/book_service.dart';

class FakeBookRepository implements BookRepository {
  final List<Book> mockData;

  FakeBookRepository(this.mockData);

  @override
  Future<List<Book>> getAll() async => mockData;

  @override
  Future<List<Book>> getRandomBooks() async => mockData;
}

void main() {
  final List<Book> mockBooks = [
    const Book(
      id: 1,
      title: 'El Gran Gatsby',
      genre: 'Clásico',
      author: 'F. Scott Fitzgerald',
      description: 'Novela clásica estadounidense.',
      salePrice: 15.99,
      purchasePrice: 10.50,
      stock: 50,
      cover: 'url_gatsby.jpg',
      language: 'Inglés',
    ),
    const Book(
      id: 2,
      title: 'Fundación',
      genre: 'Ciencia Ficción',
      author: 'Isaac Asimov',
      description: 'Inicio de la saga de ciencia ficción.',
      salePrice: 22.50,
      purchasePrice: 15.00,
      stock: 30,
      cover: 'url_fundacion.jpg',
      language: 'Español',
    ),
    const Book(
      id: 3,
      title: 'Dune',
      genre: 'ciencia ficción ',
      author: 'Frank Herbert',
      description: 'Épica de opera espacial.',
      salePrice: 25.00,
      purchasePrice: 18.00,
      stock: 10,
      cover: 'url_dune.jpg',
      language: 'Español',
    ),
    const Book(
      id: 4,
      title: 'Cien Años de Soledad',
      genre: 'CLÁSICO',
      author: 'G. García Márquez',
      description: 'Realismo mágico puro.',
      salePrice: 18.00,
      purchasePrice: 12.00,
      stock: 45,
      cover: 'url_cien_anos.jpg',
      language: 'Español',
    ),
    const Book(
      id: 5,
      title: 'El Código Da Vinci',
      genre: 'Misterio',
      author: 'Dan Brown',
      description: 'Thriller de conspiración.',
      salePrice: 12.99,
      purchasePrice: 8.00,
      stock: 60,
      cover: 'url_davinci.jpg',
      language: 'Inglés',
    ),
  ];

  late FakeBookRepository fakeRepo;
  late BookService service;

  setUp(() {
    fakeRepo = FakeBookRepository(mockBooks);
    service = BookService(fakeRepo);
  });

  group('BookService - Lógica de Negocio (Manual Mock)', () {
    test('Debe filtrar libros por género ignorando mayúsculas/minúsculas', () async {
      final resultBooks = await service.getByGenre('CLÁSICO');

      expect(resultBooks.length, 2);
      expect(resultBooks.any((b) => b.id == 1), isTrue);
      expect(resultBooks.any((b) => b.id == 4), isTrue);
    });

    test('Debe encontrar el libro por un ID de tipo String válido', () async {
      final result = await service.findBookById('3');

      expect(result, isNotNull);
      expect(result?.title, 'Dune');
    });

    test('Debe devolver null si el ID no se encuentra o tiene formato incorrecto', () async {
      final notFoundResult = await service.findBookById('999');
      expect(notFoundResult, isNull);

      final invalidFormatResult = await service.findBookById('abc');
      expect(invalidFormatResult, isNull);
    });

    test('Debe obtener todos los libros del repositorio falso', () async {
      final result = await service.getAllBooks();

      expect(result, mockBooks);
    });

    test('Debe obtener libros aleatorios del repositorio falso', () async {
      final result = await service.getRandomBooks();

      expect(result, mockBooks);
    });
  });
}
