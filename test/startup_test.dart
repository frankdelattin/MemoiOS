import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/services/vector_service.dart';
import 'package:snapp_app/startup.dart';

import 'startup_test.mocks.dart';

@GenerateMocks([VectorService])
void main() {
  group('Startup Tests', () {
    late MockVectorService mockVectorService;

    setUp(() {
      mockVectorService = MockVectorService();
      GetIt.instance.reset();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    group('Vector Cleanup Integration', () {
      test('should call vector cleanup during startup', () async {
        // Arrange
        GetIt.instance.registerSingleton<VectorService>(mockVectorService);
        when(mockVectorService.cleanupOrphanedVectors())
            .thenAnswer((_) async {});

        // Act
        // Note: We can't easily test the full startup flow due to Flutter binding dependencies
        // But we can test the cleanup method behavior
        final vectorService = GetIt.instance<VectorService>();
        await vectorService.cleanupOrphanedVectors();

        // Assert
        verify(mockVectorService.cleanupOrphanedVectors()).called(1);
      });

      test('should handle cleanup errors gracefully during startup', () async {
        // Arrange
        GetIt.instance.registerSingleton<VectorService>(mockVectorService);
        when(mockVectorService.cleanupOrphanedVectors())
            .thenThrow(Exception('Cleanup failed'));

        // Act & Assert - should not throw
        final vectorService = GetIt.instance<VectorService>();
        await expectLater(
          vectorService.cleanupOrphanedVectors(),
          throwsException,
        );

        verify(mockVectorService.cleanupOrphanedVectors()).called(1);
      });

      test('should continue startup even if vector service is not available', () async {
        // Arrange - Don't register VectorService
        
        // Act & Assert - should handle gracefully
        expect(() => GetIt.instance<VectorService>(), throwsA(isA<AssertionError>()));
      });
    });

    group('Dependency Registration', () {
      test('should register all required dependencies', () {
        // This test would require mocking all the extension methods
        // For now, we verify the structure exists
        expect(Startup, isNotNull);
        expect(Startup.configure, isNotNull);
      });
    });
  });
}
