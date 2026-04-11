import '../../../shared/features/risk_expression.dart';
import 'emotion_exception.dart';

Future<void> checkEmotionTagLimit({
  required List<int> tagIds,
  required int maxCount,
}) async {
  final int uniqueTagCount = tagIds.toSet().length;
  if (uniqueTagCount > maxCount) {
    throw const EmotionException(EmotionErrorCode.tagLimitExceeded);
  }
}

Future<void> checkEmotionContentPolicy({
  required String content,
  required int maxLength,
}) async {
  final String trimmed = content.trim();
  if (trimmed.length > maxLength) {
    throw const EmotionException(EmotionErrorCode.contentTooLong);
  }

  if (checkRiskExpression(content: trimmed)) {
    throw const EmotionException(EmotionErrorCode.contentBlockedWord);
  }
}
