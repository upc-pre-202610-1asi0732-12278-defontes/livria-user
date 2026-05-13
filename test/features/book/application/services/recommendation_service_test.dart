import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:livria_user/features/book/application/services/book_service.dart';
import 'package:livria_user/features/book/application/services/recommendation_service.dart';
import 'package:livria_user/features/book/domain/entities/book.dart';
import 'package:livria_user/features/book/domain/repositories/exclusion_repository.dart';
import 'package:livria_user/features/book/domain/repositories/recommendation_repository.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';

// 1. Mock import
import 'recommendation_service_test.mocks.dart';

// 2. Annotation strictly right above main()
@GenerateMocks([
  RecommendationRepository,
  ExclusionRepository,
  AuthLocalDataSource,
  BookService,
])
void main() {
  late MockRecommendationRepository mockRecommendationRepo;
  late MockExclusionRepository mockExclusionRepo;
  late MockAuthLocalDataSource mockAuthDs;
  late MockBookService mockBookService;
  late RecommendationService sut;

  setUp(() {
    mockRecommendationRepo = MockRecommendationRepository();
    mockExclusionRepo = MockExclusionRepository();
    mockAuthDs = MockAuthLocalDataSource();
    mockBookService = MockBookService();

    sut = RecommendationService(
      mockRecommendationRepo,
      mockExclusionRepo,
      mockAuthDs,
      mockBookService,
    );
  });

  group('AC1 – Sin sesión activa', () {
    test(
      'devuelve libros aleatorios cuando no hay userId almacenado',
      () async {
        final randomBooks = [buildBook(id: 10), buildBook(id: 11)];

        when(mockAuthDs.getUserId()).thenAnswer((_) async => null);
        when(mockBookService.getRandomBooks())
            .thenAnswer((_) async => randomBooks);

        final result = await sut.getRecommendedBooks();

        expect(result, equals(randomBooks));
        verifyNever(mockRecommendationRepo.getRecommendedBooks());
      },
    );
  });

  group('AC2 – Con sesión activa, filtra excluidos', () {
    test(
      'devuelve solo libros que NO están en la lista de exclusión',
      () async {
        const userId = 42;
        final recommended = [
          buildBook(id: 1),
          buildBook(id: 2),
          buildBook(id: 3),
        ];
        const excludedIds = [2];

        when(mockAuthDs.getUserId()).thenAnswer((_) async => userId);
        when(mockExclusionRepo.getExcludedBookIds(userId: userId))
            .thenAnswer((_) async => excludedIds);
        when(mockRecommendationRepo.getRecommendedBooks())
            .thenAnswer((_) async => recommended);

        final result = await sut.getRecommendedBooks();

        expect(result.map((b) => b.id), containsAll([1, 3]));
        expect(result.map((b) => b.id), isNot(contains(2)));
      },
    );
  });

  group('AC3 – Todos los recomendados excluidos', () {
    test(
      'activa fallback aleatorio cuando todos los recomendados están excluidos',
      () async {
        const userId = 42;
        final recommended = [buildBook(id: 1), buildBook(id: 2)];
        const excludedIds = [1, 2];
        final randomBooks = [buildBook(id: 99), buildBook(id: 100)];

        when(mockAuthDs.getUserId()).thenAnswer((_) async => userId);
        when(mockExclusionRepo.getExcludedBookIds(userId: userId))
            .thenAnswer((_) async => excludedIds);
        when(mockRecommendationRepo.getRecommendedBooks())
            .thenAnswer((_) async => recommended);
        when(mockBookService.getRandomBooks())
            .thenAnswer((_) async => randomBooks);

        final result = await sut.getRecommendedBooks();

        expect(result.map((b) => b.id), containsAll([99, 100]));
        expect(result.map((b) => b.id), isNot(contains(1)));
        expect(result.map((b) => b.id), isNot(contains(2)));
      },
    );
  });
}

// 3. Helper functions safely tucked away at the bottom
Book buildBook({required int id, String genre = 'fiction'}) => Book(
      id: id,
      title: 'Book $id',
      description: 'Description',
      author: 'Author',
      salePrice: 29.99,
      purchasePrice: 18.00,
      stock: 5,
      cover: 'cover.jpg',
      genre: genre,
      language: 'english',
    );