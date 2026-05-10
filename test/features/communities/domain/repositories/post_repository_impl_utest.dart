import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:livria_user/features/communities/domain/entities/post.dart';
import 'package:livria_user/features/communities/domain/repositories/post_repository.dart';
import 'package:livria_user/features/communities/infrastructure/datasource/post_remote_datasource.dart';
import 'package:livria_user/features/communities/domain/repositories/post_repository_impl.dart';

import 'post_repository_impl_utest.mocks.dart';

@GenerateMocks([PostRemoteDataSource])
void main() {
  late PostRepository repository;
  late MockPostRemoteDataSource mockDataSource;

  final tPost = Post(
    id: 1,
    communityId: 10,
    userId: 1,
    username: 'TestUser',
    content: 'Test content',
    img: '',
    createdAt: DateTime.parse('2023-01-01T10:00:00Z'),
  );

  final tPostJsonMap = {
    'id': 1,
    'communityId': 10,
    'userId': 1,
    'username': 'TestUser',
    'content': 'Test content',
    'img': '',
    'createdAt': '2023-01-01T10:00:00.000Z',
  };
  final tPostJson = json.encode(tPostJsonMap);

  final tPostList = [tPost, tPost];

  setUp(() {
    mockDataSource = MockPostRemoteDataSource();
    repository = PostRepositoryImpl(mockDataSource);
  });

  group('PostRepositoryImpl', () {
    group('fetchPostsByCommunityId', () {
      const tCommunityId = 10;
      const tOffset = 0;
      const tLimit = 10;

      test('debe devolver List<Post> cuando el DataSource es exitoso', () async {
        when(mockDataSource.fetchPostsByCommunityId(tCommunityId, tOffset, tLimit))
            .thenAnswer((_) async => tPostList);

        final result = await repository.fetchPostsByCommunityId(tCommunityId, tOffset, tLimit);

        verify(mockDataSource.fetchPostsByCommunityId(tCommunityId, tOffset, tLimit)).called(1);

        expect(result, isA<List<Post>>());
        expect(result.length, equals(tPostList.length));
        expect(result.first.id, equals(tPost.id));
      });

      test('debe propagar la excepción cuando el DataSource falla', () async {
        when(mockDataSource.fetchPostsByCommunityId(tCommunityId, tOffset, tLimit))
            .thenThrow(Exception('Error de conexión'));

        expect(() => repository.fetchPostsByCommunityId(tCommunityId, tOffset, tLimit),
            throwsA(isA<Exception>()));

        verify(mockDataSource.fetchPostsByCommunityId(tCommunityId, tOffset, tLimit)).called(1);
      });
    });

    group('fetchPostById', () {
      const tPostId = 1;

      test('debe devolver Post si el status code es 200', () async {
        when(mockDataSource.fetchPostById(tPostId))
            .thenAnswer((_) async => http.Response(tPostJson, 200));

        final result = await repository.fetchPostById(tPostId);

        verify(mockDataSource.fetchPostById(tPostId)).called(1);

        expect(result, isA<Post>());
        expect(result.id, equals(tPost.id));
        expect(result.username, equals(tPost.username));
      });

      test('debe lanzar Exception si el status code NO es 200', () async {
        when(mockDataSource.fetchPostById(tPostId))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        expect(() => repository.fetchPostById(tPostId),
            throwsA(isA<Exception>()));

        verify(mockDataSource.fetchPostById(tPostId)).called(1);
      });
    });

    group('createPost', () {
      const tCommunityId = 10;
      const tUsername = 'NewUser';
      const tContent = 'New content';

      test('debe devolver Post si el status code es 201', () async {
        when(mockDataSource.createPost(
          communityId: tCommunityId,
          userId: 1,
          username: tUsername,
          content: tContent,
          img: anyNamed('img'),
        )).thenAnswer((_) async => http.Response(tPostJson, 201));

        final result = await repository.createPost(
          communityId: tCommunityId,
          userId: 1,
          username: tUsername,
          content: tContent,
        );

        verify(mockDataSource.createPost(
          communityId: tCommunityId,
          userId: 1,
          username: tUsername,
          content: tContent,
          img: anyNamed('img'),
        )).called(1);

        expect(result, isA<Post>());
        expect(result.id, equals(tPost.id));
        expect(result.username, equals(tPost.username));
      });

      test('debe lanzar Exception si el status code NO es 201 o 200', () async {
        when(mockDataSource.createPost(
          communityId: tCommunityId,
          userId: 1,
          username: tUsername,
          content: tContent,
          img: anyNamed('img'),
        )).thenAnswer((_) async => http.Response('Server Error', 500));

        expect(
              () => repository.createPost(
            communityId: tCommunityId,
            userId: 1,
            username: tUsername,
            content: tContent,
          ),
          throwsA(isA<Exception>()),
        );

        verify(mockDataSource.createPost(
          communityId: tCommunityId,
          userId: 1,
          username: tUsername,
          content: tContent,
          img: anyNamed('img'),
        )).called(1);
      });
    });
  });
}
