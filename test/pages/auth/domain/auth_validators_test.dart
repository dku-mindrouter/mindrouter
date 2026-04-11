import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/auth/domain/auth_exception.dart';
import 'package:mindfulconnect/pages/auth/domain/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('checkAuthenticatedUser throws unauthenticated when user id is empty', () async {
      await expectLater(
        () => AuthValidators.checkAuthenticatedUser(userId: ''),
        throwsA(
          isA<AuthException>().having(
            (AuthException error) => error.code,
            'code',
            AuthErrorCode.unauthenticated,
          ),
        ),
      );
    });

    test('checkSessionValidity throws session expired when expiredAt is null', () async {
      await expectLater(
        () => AuthValidators.checkSessionValidity(expiresAt: null),
        throwsA(
          isA<AuthException>().having(
            (AuthException error) => error.code,
            'code',
            AuthErrorCode.sessionExpired,
          ),
        ),
      );
    });

    test('checkProfileCompleted throws profile incomplete when nickname missing', () async {
      await expectLater(
        () => AuthValidators.checkProfileCompleted(nickname: '  '),
        throwsA(
          isA<AuthException>().having(
            (AuthException error) => error.code,
            'code',
            AuthErrorCode.profileIncomplete,
          ),
        ),
      );
    });

    test('checkNicknamePolicy throws invalid nickname on invalid length', () async {
      await expectLater(
        () => AuthValidators.checkNicknamePolicy(nickname: 'a'),
        throwsA(
          isA<AuthException>().having(
            (AuthException error) => error.code,
            'code',
            AuthErrorCode.invalidNickname,
          ),
        ),
      );
    });

    test('checkNicknamePolicy throws blocked word code on blocked word', () async {
      await expectLater(
        () => AuthValidators.checkNicknamePolicy(nickname: 'admin_user'),
        throwsA(
          isA<AuthException>().having(
            (AuthException error) => error.code,
            'code',
            AuthErrorCode.nicknameBlockedWord,
          ),
        ),
      );
    });

    test('checkNicknamePolicy passes for valid nickname', () async {
      await AuthValidators.checkNicknamePolicy(nickname: '좋은하루_12');
    });
  });
}
