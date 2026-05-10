import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:livria_user/features/communities/application/services/community_service.dart';
import 'package:livria_user/features/communities/domain/entities/community.dart';
import 'package:livria_user/features/communities/domain/repositories/community_repository.dart';

import 'community_service_utest.mocks.dart';

@GenerateMocks([CommunityRepository])
void main() {
  late MockCommunityRepository mockRepo;
  late CommunityService service;

  final tCommunityList = [
    Community(
      id: 1,
      name: 'Test Club',
      description: 'Test Desc',
      type: 1,
      ownerId: 3,
      image: '',
      banner: '',
    ),
  ];

  setUp(() {
    mockRepo = MockCommunityRepository();
    service = CommunityService(mockRepo);
  });

  group('CommunityService', () {
    test('debe llamar a fetchCommunityList en el repositorio con offset y limit correctos', () async {
      const tOffset = 10;
      const tLimit = 20;

      when(mockRepo.fetchCommunityList(tOffset, tLimit))
          .thenAnswer((_) async => tCommunityList);

      final result = await service.getCommunityList(tOffset, tLimit);

      expect(result, equals(tCommunityList));
      verify(mockRepo.fetchCommunityList(tOffset, tLimit)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('debe llamar a searchCommunities en el repositorio con la query correcta', () async {
      const tQuery = 'Ficción';

      when(mockRepo.searchCommunities(tQuery))
          .thenAnswer((_) async => tCommunityList);

      final result = await service.findCommunities(tQuery);

      expect(result, equals(tCommunityList));
      verify(mockRepo.searchCommunities(tQuery)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });
}
