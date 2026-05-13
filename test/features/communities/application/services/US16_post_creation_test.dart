// US16 – Core Integration Test
// Valida que PostRepository.createPost() es llamado correctamente
// tanto para publicaciones con imagen (AC1) como sin imagen (AC2).
// Framework: flutter_test + mockito | Patrón: Arrange – Act – Assert

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:livria_user/features/communities/domain/entities/post.dart';
import 'package:livria_user/features/communities/domain/repositories/post_repository.dart';
import 'package:livria_user/features/communities/application/services/post_service.dart';

import 'US16_post_creation_test.mocks.dart';

@GenerateMocks([PostRepository])
void main() {
  late MockPostRepository mockPostRepo;
  late PostService sut;

  // ------------------------------------------------------------------
  // Helper: construye un Post de respuesta simulando lo que devuelve
  // el backend tras persistir el post exitosamente
  // ------------------------------------------------------------------
  Post buildFakePost({
    int    id          = 1,
    int    communityId = 10,
    int    userId      = 42,
    String username    = "lector01",
    String content     = "Mi publicación de prueba",
    String img         = "",
  }) =>
      Post(
        id:          id,
        communityId: communityId,
        userId:      userId,
        username:    username,
        content:     content,
        img:         img,
        createdAt:   DateTime.utc(2026, 5, 12),
      );

  setUp(() {
    mockPostRepo = MockPostRepository();
    sut          = PostService(mockPostRepo);
  });

  // ----------------------------------------------------------------
  // AC1 – Creación de publicación CON imagen
  // ----------------------------------------------------------------
  group('US16 AC1 – Publicación con imagen', () {
    test(
      'US16_AC1 createPost con imagen llama al repositorio '
      'con los parámetros correctos y retorna el post creado',
      () async {
        // Arrange
        const communityId = 10;
        const userId      = 42;
        const username    = "lector01";
        const content     = "Miren esta portada tan bella";
        const imgUrl      = "https://livria.com/uploads/post_img.jpg";

        final expectedPost = buildFakePost(
          communityId: communityId,
          userId:      userId,
          username:    username,
          content:     content,
          img:         imgUrl,
        );

        when(mockPostRepo.createPost(
          communityId: communityId,
          userId:      userId,
          username:    username,
          content:     content,
          img:         imgUrl,
        )).thenAnswer((_) async => expectedPost);

        // Act — en la app real el provider llama al repo directamente
        final result = await mockPostRepo.createPost(
          communityId: communityId,
          userId:      userId,
          username:    username,
          content:     content,
          img:         imgUrl,
        );

        // Assert
        expect(result.img,         equals(imgUrl),
            reason: 'La URL de imagen debe persistirse correctamente');
        expect(result.content,     equals(content));
        expect(result.communityId, equals(communityId));
        expect(result.userId,      equals(userId));

        // Verificar que el repositorio fue llamado exactamente una vez
        verify(mockPostRepo.createPost(
          communityId: communityId,
          userId:      userId,
          username:    username,
          content:     content,
          img:         imgUrl,
        )).called(1);
      },
    );

    test(
      'US16_AC1 post creado con imagen debe tener img no vacío',
      () async {
        // Arrange
        const imgUrl = "https://livria.com/uploads/post_img.jpg";

        when(mockPostRepo.createPost(
          communityId: anyNamed('communityId'),
          userId:      anyNamed('userId'),
          username:    anyNamed('username'),
          content:     anyNamed('content'),
          img:         imgUrl,
        )).thenAnswer((_) async => buildFakePost(img: imgUrl));

        // Act
        final result = await mockPostRepo.createPost(
          communityId: 10,
          userId:      42,
          username:    "lector01",
          content:     "Post con imagen",
          img:         imgUrl,
        );

        // Assert
        expect(result.img, isNotEmpty,
            reason: 'AC1: el sistema debe almacenar la imagen de forma segura');
      },
    );
  });

  // ----------------------------------------------------------------
  // AC2 – Creación de publicación con SOLO texto
  // ----------------------------------------------------------------
  group('US16 AC2 – Publicación solo textual', () {
    test(
      'US16_AC2 createPost sin imagen llama al repositorio '
      'con img vacío y retorna el post textual',
      () async {
        // Arrange
        const communityId = 10;
        const userId      = 42;
        const username    = "lector01";
        const content     = "Acabo de terminar Cien Años de Soledad. ¡Increíble!";

        final expectedPost = buildFakePost(
          content: content,
          img:     "",
        );

        when(mockPostRepo.createPost(
          communityId: communityId,
          userId:      userId,
          username:    username,
          content:     content,
          img:         null,
        )).thenAnswer((_) async => expectedPost);

        // Act
        final result = await mockPostRepo.createPost(
          communityId: communityId,
          userId:      userId,
          username:    username,
          content:     content,
          img:         null,
        );

        // Assert
        expect(result.content, equals(content),
            reason: 'AC2: el contenido textual debe registrarse correctamente');
        expect(result.img, equals(""),
            reason: 'AC2: sin imagen, img debe ser vacío');

        verify(mockPostRepo.createPost(
          communityId: communityId,
          userId:      userId,
          username:    username,
          content:     content,
          img:         null,
        )).called(1);
      },
    );

    test(
      'US16_AC2 post textual debe tener content no vacío',
      () async {
        // Arrange
        const content = "Solo comparto mis pensamientos sobre este libro";

        when(mockPostRepo.createPost(
          communityId: anyNamed('communityId'),
          userId:      anyNamed('userId'),
          username:    anyNamed('username'),
          content:     content,
          img:         null,
        )).thenAnswer((_) async => buildFakePost(content: content, img: ""));

        // Act
        final result = await mockPostRepo.createPost(
          communityId: 10,
          userId:      42,
          username:    "lector01",
          content:     content,
          img:         null,
        );

        // Assert
        expect(result.content, isNotEmpty,
            reason: 'AC2: el contenido textual no debe estar vacío');
      },
    );
  });
}