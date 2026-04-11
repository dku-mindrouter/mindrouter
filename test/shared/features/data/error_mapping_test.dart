import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/shared/features/data/error_mapping.dart';

class FakeSupabaseLikeError {
  FakeSupabaseLikeError({this.code, this.details, this.message});

  final String? code;
  final dynamic details;
  final String? message;
}

void main() {
  group('parsePostgrestErrorCode', () {
    test('uses error.code first', () {
      final String code = parsePostgrestErrorCode(error: {
        'code': 'UNAUTHORIZED',
        'details': {'APP_ERROR_CODE': 'FORBIDDEN'},
        'message': 'fallback',
      });

      expect(code, 'UNAUTHORIZED');
    });

    test('uses details.APP_ERROR_CODE when code is missing', () {
      final String code = parsePostgrestErrorCode(error: {
        'details': {'APP_ERROR_CODE': 'FORBIDDEN'},
        'message': 'fallback',
      });

      expect(code, 'FORBIDDEN');
    });

    test(
      'extracts known code from message when previous fields are missing',
      () {
        final String code = parsePostgrestErrorCode(error: {
          'message': 'rpc failed: INVALID_ARGUMENT',
        });

        expect(code, 'INVALID_ARGUMENT');
      },
    );

    test('falls back to INTERNAL_ERROR on unknown message text', () {
      final String code = parsePostgrestErrorCode(error: {
        'message': 'unexpected postgres failure',
      });

      expect(code, 'INTERNAL_ERROR');
    });

    test('falls back to INTERNAL_ERROR', () {
      final String code = parsePostgrestErrorCode(error: Object());

      expect(code, 'INTERNAL_ERROR');
    });

    test('reads code from object style errors', () {
      final String code = parsePostgrestErrorCode(
        error:
        FakeSupabaseLikeError(code: 'FORBIDDEN'),
      );

      expect(code, 'FORBIDDEN');
    });

    test('reads APP_ERROR_CODE from object details map', () {
      final String code = parsePostgrestErrorCode(
        error:
        FakeSupabaseLikeError(details: {'APP_ERROR_CODE': 'UNAUTHORIZED'}),
      );

      expect(code, 'UNAUTHORIZED');
    });
  });
}
