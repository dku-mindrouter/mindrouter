import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/shared/features/risk_expression.dart';

void main() {
  group('checkRiskExpression', () {
    test('returns false for safe text', () {
      expect(checkRiskExpression(content: '오늘은 차분하게 하루를 보냈어요.'), isFalse);
    });

    test('returns true when blocked word is included', () {
      expect(checkRiskExpression(content: '진짜 시발 너무 힘들다'), isTrue);
    });
  });
}
