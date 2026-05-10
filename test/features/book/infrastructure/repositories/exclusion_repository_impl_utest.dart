import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:livria_user/features/book/infrastructure/datasource/exclusion_remote_datasource.dart';
import 'package:livria_user/features/book/infrastructure/repositories/exclusion_repository_impl.dart';

@GenerateMocks([ExclusionRemoteDataSource])
import 'exclusion_repository_impl_utest.mocks.dart';

void main() {
  late ExclusionRepositoryImpl repository;
  late MockExclusionRemoteDataSource mockRemoteDataSource;

  const int testUserId = 1;
  const int testBookId = 101;
  const List<int> testExcludedList = [102, 103, 104];

  setUp(() {
    mockRemoteDataSource = MockExclusionRemoteDataSource();
    repository = ExclusionRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('ExclusionRepositoryImpl', () {
    test('addToExclusions debe llamar a postExclusion', () async {
      when(mockRemoteDataSource.postExclusion(
        userId: anyNamed('userId'),
        bookId: anyNamed('bookId'),
      )).thenAnswer((_) async {});

      await repository.addToExclusions(
        userId: testUserId,
        bookId: testBookId,
      );

      verify(mockRemoteDataSource.postExclusion(
        userId: testUserId,
        bookId: testBookId,
      )).called(1);
    });

    test('removeFromExclusions debe llamar a deleteExclusion', () async {
      when(mockRemoteDataSource.deleteExclusion(
        userId: anyNamed('userId'),
        bookId: anyNamed('bookId'),
      )).thenAnswer((_) async {});

      await repository.removeFromExclusions(
        userId: testUserId,
        bookId: testBookId,
      );

      verify(mockRemoteDataSource.deleteExclusion(
        userId: testUserId,
        bookId: testBookId,
      )).called(1);
    });

    test('checkIsExcluded debe devolver el resultado de getExclusionStatus', () async {
      when(mockRemoteDataSource.getExclusionStatus(
        userId: anyNamed('userId'),
        bookId: anyNamed('bookId'),
      )).thenAnswer((_) async => true);

      final result = await repository.checkIsExcluded(
        userId: testUserId,
        bookId: testBookId,
      );

      expect(result, isTrue);
      verify(mockRemoteDataSource.getExclusionStatus(
        userId: testUserId,
        bookId: testBookId,
      )).called(1);
    });

    test('getExcludedBookIds debe devolver la lista', () async {
      when(mockRemoteDataSource.getExclusionsList(
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => testExcludedList);

      final result = await repository.getExcludedBookIds(userId: testUserId);

      expect(result, equals(testExcludedList));
      verify(mockRemoteDataSource.getExclusionsList(
        userId: testUserId,
      )).called(1);
    });
  });
}
