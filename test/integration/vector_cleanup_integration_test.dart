import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/onnx_runtime_service.dart';
import 'package:snapp_app/services/vector_service.dart';

import '../services/vector_service_test.mocks.dart';

@GenerateMocks([ImageVectorsRepository, ImageService, OnnxRuntimeService])
void main() {
  group('Vector Cleanup Integration Tests', () {
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

    group('Real-world Scenarios', () {
      test('should handle typical user scenario: some photos deleted', () async {
        // Arrange - Simulate user had 10 photos, deleted 3
        final originalVectorIds = {
          'photo1', 'photo2', 'photo3', 'photo4', 'photo5',
          'photo6', 'photo7', 'photo8', 'photo9', 'photo10'
        };
        final remainingGalleryIds = {
          'photo1', 'photo2', 'photo4', 'photo5', 'photo6', 'photo7'
          // photo3, photo8, photo9, photo10 were deleted
        };
        final expectedOrphanedIds = {'photo3', 'photo8', 'photo9', 'photo10'};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => originalVectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => remainingGalleryIds);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenAnswer((_) async {});

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.deleteAllByImageIds(expectedOrphanedIds)).called(1);
      });

      test('should handle edge case: user deleted all photos', () async {
        // Arrange
        final originalVectorIds = {'photo1', 'photo2', 'photo3'};
        final emptyGalleryIds = <String>{};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => originalVectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => emptyGalleryIds);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenAnswer((_) async {});

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.deleteAllByImageIds(originalVectorIds)).called(1);
      });

      test('should handle edge case: user added new photos (no cleanup needed)', () async {
        // Arrange
        final originalVectorIds = {'photo1', 'photo2'};
        final expandedGalleryIds = {'photo1', 'photo2', 'photo3', 'photo4'};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => originalVectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => expandedGalleryIds);

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verifyNever(mockImageVectorsRepository.deleteAllByImageIds(any));
      });

      test('should handle mixed scenario: some deleted, some added', () async {
        // Arrange
        final originalVectorIds = {'photo1', 'photo2', 'photo3', 'photo4'};
        final mixedGalleryIds = {'photo1', 'photo3', 'photo5', 'photo6'};
        // photo2, photo4 deleted; photo5, photo6 added
        final expectedOrphanedIds = {'photo2', 'photo4'};
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => originalVectorIds);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => mixedGalleryIds);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenAnswer((_) async {});

        // Act
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockImageVectorsRepository.deleteAllByImageIds(expectedOrphanedIds)).called(1);
      });
    });

    group('Performance and Scale Tests', () {
      test('should handle large number of vectors efficiently', () async {
        // Arrange - Simulate 1000 vectors, 100 deleted
        final largeVectorSet = List.generate(1000, (i) => 'photo$i').toSet();
        final largeGallerySet = List.generate(900, (i) => 'photo$i').toSet();
        final expectedOrphanedCount = 100;
        
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => largeVectorSet);
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => largeGallerySet);
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenAnswer((_) async {});

        // Act
        final stopwatch = Stopwatch()..start();
        await vectorService.cleanupOrphanedVectors();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete quickly
        verify(mockImageVectorsRepository.deleteAllByImageIds(any)).called(1);
        
        // Verify the correct number of orphaned vectors were identified
        final capturedArgs = verify(mockImageVectorsRepository.deleteAllByImageIds(captureAny)).captured;
        final orphanedIds = capturedArgs.first as Set<String>;
        expect(orphanedIds.length, equals(expectedOrphanedCount));
      });

      test('should handle empty database efficiently', () async {
        // Arrange
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => <String>{});

        // Act
        final stopwatch = Stopwatch()..start();
        await vectorService.cleanupOrphanedVectors();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
        verifyNever(mockImageService.getAllImageIds());
        verifyNever(mockImageVectorsRepository.deleteAllByImageIds(any));
      });
    });

    group('Error Recovery Tests', () {
      test('should recover from database read errors', () async {
        // Arrange
        when(mockImageVectorsRepository.getAllImageIds())
            .thenThrow(Exception('Database connection failed'));

        // Act & Assert
        await expectLater(
          vectorService.cleanupOrphanedVectors(),
          completes,
        );
      });

      test('should recover from gallery access errors', () async {
        // Arrange
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => {'photo1', 'photo2'});
        when(mockImageService.getAllImageIds())
            .thenThrow(Exception('Gallery permission denied'));

        // Act & Assert
        await expectLater(
          vectorService.cleanupOrphanedVectors(),
          completes,
        );
      });

      test('should recover from deletion errors', () async {
        // Arrange
        when(mockImageVectorsRepository.getAllImageIds())
            .thenAnswer((_) async => {'photo1', 'photo2'});
        when(mockImageService.getAllImageIds())
            .thenAnswer((_) async => {'photo1'});
        when(mockImageVectorsRepository.deleteAllByImageIds(any))
            .thenThrow(Exception('Database write failed'));

        // Act & Assert
        await expectLater(
          vectorService.cleanupOrphanedVectors(),
          completes,
        );
      });
    });
  });
}
