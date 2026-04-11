import 'emotion_composer_state.dart';
import 'emotion_exception.dart';

EmotionComposerState toggleEmotionTag({
  required EmotionComposerState state,
  required int tagId,
  required int maxTags,
}) {
  final List<int> nextTags = List<int>.from(state.selectedTagIds);
  final int existingIndex = nextTags.indexOf(tagId);
  if (existingIndex >= 0) {
    nextTags.removeAt(existingIndex);
    return state.copyWith(selectedTagIds: nextTags);
  }

  if (nextTags.length >= maxTags) {
    throw const EmotionException(EmotionErrorCode.tagLimitExceeded);
  }

  nextTags.add(tagId);
  return state.copyWith(selectedTagIds: nextTags);
}

bool checkCanSubmitEmotion({
  required List<int> tagIds,
  required bool isSubmitting,
}) {
  return tagIds.isNotEmpty && !isSubmitting;
}
