// US TEST 12

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:livria_user/features/book/domain/entities/book.dart';
import 'package:livria_user/features/book/domain/repositories/book_repository_impl.dart';
import 'package:livria_user/features/book/infrastructure/datasource/book_remote_datasource.dart';

class FakeBookRemoteDataSource implements BookRemoteDataSource {
  late http.Response Function() _getAllBooksHandler;
  late http.Response Function(int id) _getBookHandler;

  void setGetAllBooksResponse(int statusCode, String body, {String? reasonPhrase}) {
    _getAllBooksHandler = () => http.Response(body, statusCode, reasonPhrase: reasonPhrase);
  }

  void setGetBookResponse(int id, int statusCode, String body, {String? reasonPhrase}) {
    _getBookHandler = (requestedId) =>
    (requestedId == id) ? http.Response(body, statusCode, reasonPhrase: reasonPhrase) : http.Response('Not Found', 404);
  }

  @override
  Future<http.Response> getAllBooks() async {
    await Future.delayed(Duration.zero);
    return _getAllBooksHandler();
  }

  @override
  Future<http.Response> getBook(int id) async {
    await Future.delayed(Duration.zero);
    return _getBookHandler(id);
  }
}

void main() {
  late FakeBookRemoteDataSource fakeDs;
  late BookRepositoryImpl repository;

  const String mockBooksJson = '''
    [
      {
        "id": 1,
        "title": "Cien Años de Soledad",
        "genre": "Ficción",
        "author": "G.G.M",
        "description": "Una saga.",
        "salePrice": 20.0,
        "purchasePrice": 10.0,
        "stock": 50,
        "cover": "url1.jpg",
        "language": "Español"
      },
      {
        "id": 2,
        "title": "Fundación",
        "genre": "Ciencia Ficción",
        "author": "I.A.",
        "description": "El imperio galáctico.",
        "salePrice": 25.5,
        "purchasePrice": 15.0,
        "stock": 30,
        "cover": "url2.jpg",
        "language": "Inglés"
      },
      {
        "id": 3,
        "title": "Dune",
        "genre": "Ciencia Ficción",
        "author": "F.H.",
        "description": "El planeta desierto.",
        "salePrice": 30.0,
        "purchasePrice": 18.0,
        "stock": 10,
        "cover": "url3.jpg",
        "language": "Español"
      },
      {
        "id": 4,
        "title": "1984",
        "genre": "Distopía",
        "author": "G.O.",
        "description": "Big Brother.",
        "salePrice": 15.0,
        "purchasePrice": 9.0,
        "stock": 60,
        "cover": "url4.jpg",
        "language": "Inglés"
      },
      {
        "id": 5,
        "title": "Orgullo y Prejuicio",
        "genre": "Clásico",
        "author": "J.A.",
        "description": "Romance clásico.",
        "salePrice": 18.0,
        "purchasePrice": 11.0,
        "stock": 40,
        "cover": "url5.jpg",
        "language": "Inglés"
      },
      {
        "id": 6,
        "title": "El Hobbit",
        "genre": "Fantasía",
        "author": "J.R.R.T.",
        "description": "Un viaje inesperado.",
        "salePrice": 22.0,
        "purchasePrice": 14.0,
        "stock": 25,
        "cover": "url6.jpg",
        "language": "Español"
      },
      {
        "id": 7,
        "title": "El Código Da Vinci",
        "genre": "Misterio",
        "author": "D.B.",
        "description": "Thriller.",
        "salePrice": 17.5,
        "purchasePrice": 11.5,
        "stock": 55,
        "cover": "url7.jpg",
        "language": "Inglés"
      }
    ]
  ''';

  setUp(() {
    fakeDs = FakeBookRemoteDataSource();
    repository = BookRepositoryImpl(fakeDs);
  });

  group('BookRepositoryImpl - getAll()', () {
    test('Should return a List<Book> when status code is 2xx', () async {
      fakeDs.setGetAllBooksResponse(200, mockBooksJson);

      final result = await repository.getAll();

      expect(result, isA<List<Book>>());
      expect(result.length, 7);
      expect(result.first.id, 1);
      expect(result.first.salePrice, 20.0);
    });

    test('Should throw an exception when status code is not 2xx', () async {
      fakeDs.setGetAllBooksResponse(404, 'Not Found', reasonPhrase: 'Not Found');

      expect(
            () => repository.getAll(),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message', contains('HTTP 404')),
        ),
      );
    });
  });

  group('BookRepositoryImpl - getRandomBooks()', () {
    test('Should return exactly 6 randomly shuffled books when more than 6 are available', () async {
      fakeDs.setGetAllBooksResponse(200, mockBooksJson);

      final result = await repository.getRandomBooks();

      expect(result, isA<List<Book>>());
      expect(result.length, 6);
    });

    test('Should return all available books when 6 or less are available', () async {
      const smallBooksJson = '''
        [
          {"id": 1, "title": "A", "genre": "C", "author": "X", "description": "d", "salePrice": 1, "purchasePrice": 1, "stock": 1, "cover": "url", "language": "E"},
          {"id": 2, "title": "B", "genre": "D", "author": "W", "description": "d", "salePrice": 1, "purchasePrice": 1, "stock": 1, "cover": "url", "language": "E"},
          {"id": 3, "title": "C", "genre": "E", "author": "V", "description": "d", "salePrice": 1, "purchasePrice": 1, "stock": 1, "cover": "url", "language": "E"}
        ]
      ''';

      fakeDs.setGetAllBooksResponse(200, smallBooksJson);

      final result = await repository.getRandomBooks();

      expect(result.length, 3);
    });
  });
}
