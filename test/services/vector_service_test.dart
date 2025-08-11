import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:snapp_app/data/enums/image_vector_status.dart';
import 'package:snapp_app/data/image_vectors_box.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/onnx_runtime_service.dart';
import 'package:snapp_app/services/vector_service.dart';

import 'vector_service_test.mocks.dart';

@GenerateMocks([ImageVectorsRepository, ImageService, OnnxRuntimeService])
void main() {
  group('VectorService Tests', () {
    late VectorService vectorService;
    late MockImageVectorsRepository mockImageVectorsRepository;
    late MockImageService mockImageService;
    late MockOnnxRuntimeService mockOnnxRuntimeService;

    setUp(() {
      mockImageVectorsRepository = MockImageVectorsRepository();
      mockImageService = MockImageService();
      mockOnnxRuntimeService = MockOnnxRuntimeService();
      
      vectorService = VectorService(
        imageVectorsRepository: mockImageVectorsRepository,
        imageService: mockImageService,
        onnxRuntimeService: mockOnnxRuntimeService,
      );
    });

    group('cleanupOrphanedVectors', () {
      test('should skip cleanup when no vectors exist in database', () async {
        // Arrange
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => <String>{});

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.getAllImageIds()).called(1);
        verifyNever(mockImageService.getAllImageIds());
        verifyNever(mockImageVectorsRepository.deleteAllByImageIds(any));
      });

      test('should skip cleanup when no orphaned vectors exist', () async {
        // Arrange
        final vectorIds = {'image1', 'image2', 'image3'};
        final galleryIds = {'image1', 'image2', 'image3', 'image4'}; // Gallery has more images
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => vectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => galleryIds);

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.getAllImageIds()).called(1);
        verify(mockImageService.getAllImageIds()).called(1);
        verifyNever(mockImageVectorsRepository.deleteAllByImageIds(any));
      });

      test('should delete orphaned vectors when they exist', () async {
        // Arrange
        final vectorIds = {'image1', 'image2', 'image3', 'image4'};
        final galleryIds = {'image1', 'image3'}; // image2 and image4 are orphaned
        final expectedOrphanedIds = {'image2', 'image4'};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => vectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => galleryIds);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenAnswer((_) async {});

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.getAllImageIds()).called(1);
        verify(mockImageService.getAllImageIds()).called(1);
        verify(mockImageVectorsRepository.deleteAllByImageIds(expectedOrphanedIds)).called(1);
      });

      test('should handle all vectors being orphaned', () async {
        // Arrange
        final vectorIds = {'image1', 'image2', 'image3'};
        final galleryIds = <String>{}; // No images in gallery
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => vectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => galleryIds);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenAnswer((_) async {});

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.getAllImageIds()).called(1);
        verify(mockImageService.getAllImageIds()).called(1);
        verify(mockImageVectorsRepository.deleteAllByImageIds(vectorIds)).called(1);
      });

      test('should handle single orphaned vector', () async {
        // Arrange
        final vectorIds = {'image1', 'image2'};
        final galleryIds = {'image1'}; // Only image2 is orphaned
        final expectedOrphanedIds = {'image2'};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => vectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => galleryIds);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenAnswer((_) async {});

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.deleteAllByImageIds(expectedOrphanedIds)).called(1);
      });

      test('should handle errors gracefully and not throw', () async {
        // Arrange
        when(mockImageVectorsRepository.getAllImageIds())
            .thenThrow(Exception('Database error'));

        // Act & Assert - should not throw
        await expectLater(
          vectorService.cleanupOrphanedVectors(),
          completes,
        );
        
        verify(mockImageVectorsRepository.getAllImageIds()).called(1);
      });

      test('should handle repository deletion errors gracefully', () async {
        // Arrange
        final vectorIds = {'image1', 'image2'};
        final galleryIds = {'image1'};
        final expectedOrphanedIds = {'image2'};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => vectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => galleryIds);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenThrow(Exception('Deletion failed'));

        // Act & Assert - should not throw
        await expectLater(
          vectorService.cleanupOrphanedVectors(),
          completes,
        );
        
        verify(mockImageVectorsRepository.deleteAllByImageIds(expectedOrphanedIds)).called(1);
      });

      test('should handle image service errors gracefully', () async {
        // Arrange
        final vectorIds = {'image1', 'image2'};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => vectorIds);
        when(mockImageService.getAllImageIds())
            .thenThrow(Exception('Gallery access error'));

        // Act & Assert - should not throw
        await expectLater(
          vectorService.cleanupOrphanedVectors(),
          completes,
        );
        
        verify(mockImageVectorsRepository.getAllImageIds()).called(1);
        verify(mockImageService.getAllImageIds()).called(1);
        verifyNever(mockImageVectorsRepository.deleteAllByImageIds(any));
      });
    });

    group('Vector Operations', () {
      test('should calculate cosine distance correctly', () {
        // Arrange
        final vector1 = [1.0, 0.0, 0.0];
        final vector2 = [0.0, 1.0, 0.0];

        // Act
        final distance = vectorService.cosineDistance(vector1, vector2);

        // Assert
        expect(distance, equals(0.0)); // Perpendicular vectors
      });

      test('should normalize vector correctly', () {
        // Arrange
        final vector = [3.0, 4.0]; // Length = 5

        // Act
        final normalized = vectorService.normalizeVector(vector);

        // Assert
        expect(normalized[0], closeTo(0.6, 0.001)); // 3/5
        expect(normalized[1], closeTo(0.8, 0.001)); // 4/5
      });

      test('should calculate vector norm correctly', () {
        // Arrange
        final vector = [3.0, 4.0]; // Should have norm = 5

        // Act
        final norm = vectorService.vectorNorm(vector);

        // Assert
        expect(norm, closeTo(5.0, 0.001));
      });
    });
  });
}
