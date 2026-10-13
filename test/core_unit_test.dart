import 'package:flutter_test/flutter_test.dart';
import 'package:sahifile/core/errors/app_error.dart';
import 'package:sahifile/core/models/result.dart';
import 'package:sahifile/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('formatBytes handles zero and small bytes', () {
      expect(Formatters.formatBytes(0), '0 B');
      expect(Formatters.formatBytes(512), '512 B');
      expect(Formatters.formatBytes(1024), '1 KB');
      expect(Formatters.formatBytes(50 * 1024), '50 KB');
      expect(Formatters.formatBytes(1024 * 1024), '1 MB');
      expect(Formatters.formatBytes((2.5 * 1024 * 1024).round()), '2.5 MB');
    });

    test('formatDimensions returns pixel formatted string', () {
      expect(Formatters.formatDimensions(413, 531), '413 × 531 px');
      expect(Formatters.formatDimensions(0, 0), 'Unknown size');
      expect(Formatters.formatDimensions(-1, 200), 'Unknown size');
    });

    test('formatSafeFileName strips invalid characters', () {
      expect(
        Formatters.formatSafeFileName('my photo #1!', 'jpg'),
        'my_photo_1.jpg',
      );
      expect(
        Formatters.formatSafeFileName('document copy', '.pdf'),
        'document_copy.pdf',
      );
    });

    test('generateTimestampFileName includes prefix and date pattern', () {
      final name = Formatters.generateTimestampFileName('photo', 'jpg');
      expect(name.startsWith('photo_'), isTrue);
      expect(name.endsWith('.jpg'), isTrue);
    });
  });

  group('AppError & Result Monad Tests', () {
    test(
      'AppError.targetSizeImpossible contains actionable message and suggestion',
      () {
        final error = AppError.targetSizeImpossible(
          requestedKb: 50,
          achievedKb: 75,
        );
        expect(error.code, AppErrorCode.targetSizeImpossible);
        expect(error.message, contains('50 KB'));
        expect(error.message, contains('75 KB'));
        expect(error.suggestion, isNotNull);
      },
    );

    test('Result.when branches correctly on Success and Failure', () {
      const Result<int> success = Success(42);
      final successValue = success.when(
        onSuccess: (data) => 'Value: $data',
        onFailure: (err) => 'Error',
      );
      expect(successValue, 'Value: 42');
      expect(success.isSuccess, isTrue);
      expect(success.isFailure, isFalse);
      expect(success.dataOrNull, 42);

      final Result<int> failure = Failure(AppError.fileNotFound('test.jpg'));
      final failureValue = failure.when(
        onSuccess: (data) => 'Value: $data',
        onFailure: (err) => err.title,
      );
      expect(failureValue, 'File Not Found');
      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.errorOrNull?.code, AppErrorCode.fileNotFound);
    });
  });
}
