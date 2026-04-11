import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/auth/domain/auth_route_policy.dart';

void main() {
  test('resolveAuthNextRoute returns emotion', () {
    expect(resolveAuthNextRoute(), 'emotion');
  });
}
