import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:snapp_app/data/enums/image_vector_status.dart';
import 'package:snapp_app/data/image_vectors_box.dart';
import 'package:snapp_app/repositories/image_vectors_repository.dart';
import 'package:snapp_app/objectbox.g.dart';

import 'image_vectors_repository_test.mocks.dart';

@GenerateMocks([Store, Box<ImageVectorsBox>])
void main() {
  group('ImageVectorsRepository Tests', () {
    late ImageVectorsRepository repository;
    late MockStore mockStore;
    late MockBox<ImageVectorsBox> mockBox;

    setUp(() {
      mockStore = MockStore();
      mockBox = MockBox<ImageVectorsBox>();
      when(mockStore.box<ImageVectorsBox>()).thenReturn(mockBox);
      repository = ImageVectorsRepository(objectStore: mockStore);
    });

    group('getAllImageIds', () {
      test('should return empty set when no vectors exist', () async {
        // Arrange
        when(mockBox.getAll()).thenReturn([]);

        // Act
        final result = await repository.getAllImageIds();

        // Assert
        expect(result, isEmpty);
        expect(result, isA<Set<String>>());
      });

      test('should return all image IDs from database', () async {
        // Arrange
        final testVectors = [
          ImageVectorsBox(
            imageId: 'image1',
            vectors: Float32List.fromList([1.0, 2.0, 3.0]),
            status: ImageVectorStatus.success,
            createdAt: DateTime.now(),
            imageModifiedDate: 1234567890,
          ),
          ImageVectorsBox(
            imageId: 'image2',
            vectors: Float32List.fromList([4.0, 5.0, 6.0]),
            status: ImageVectorStatus.success,
            createdAt: DateTime.now(),
            imageModifiedDate: 1234567891,
          ),
          ImageVectorsBox(
            imageId: 'image3',
            vectors: Float32List.fromList([7.0, 8.0, 9.0]),
            status: ImageVectorStatus.error,
            createdAt: DateTime.now(),
            imageModifiedDate: 1234567892,
          ),
        ];
        when(mockBox.getAll()).thenReturn(testVectors);

        // Act
        final result = await repository.getAllImageIds();

        // Assert
        expect(result, hasLength(3));
        expect(result, contains('image1'));
        expect(result, contains('image2'));
        expect(result, contains('image3'));
        expect(result, isA<Set<String>>());
      });

      test('should handle duplicate image IDs correctly', () async {
        // Arrange
        final testVectors = [
          ImageVectorsBox(
            imageId: 'image1',
            vectors: Float32List.fromList([1.0, 2.0, 3.0]),
            status: ImageVectorStatus.success,
            createdAt: DateTime.now(),
            imageModifiedDate: 1234567890,
          ),
          ImageVectorsBox(
            imageId: 'image1', // Duplicate ID
            vectors: Float32List.fromList([4.0, 5.0, 6.0]),
            status: ImageVectorStatus.success,
            createdAt: DateTime.now(),
            imageModifiedDate: 1234567891,
          ),
        ];
        when(mockBox.getAll()).thenReturn(testVectors);

        // Act
        final result = await repository.getAllImageIds();

        // Assert
        expect(result, hasLength(1));
        expect(result, contains('image1'));
      });
    });

    group('deleteAllByImageIds', () {
      test('should call deleteByQuery with correct condition', () async {
        // Arrange
        final imageIds = {'image1', 'image2', 'image3'};
        
        // Act
        await repository.deleteAllByImageIds(imageIds);

        // Assert
        verify(mockBox.query(any)).called(1);
      });

      test('should handle empty set gracefully', () async {
        // Arrange
        final imageIds = <String>{};
        
        // Act & Assert - should not throw
        await repository.deleteAllByImageIds(imageIds);
      });
    });
  });
}
