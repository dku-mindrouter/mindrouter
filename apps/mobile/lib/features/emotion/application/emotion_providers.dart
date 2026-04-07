import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/emotion_tag.dart';
import '../data/emotion_repository.dart';
import '../data/mock_emotion_repository.dart';
import '../data/supabase_emotion_repository.dart';
import 'emotion_composer_state.dart';

final emotionRepositoryProvider = Provider<EmotionRepository>((ref) {
  if (AppEnv.hasSupabase) {
    return SupabaseEmotionRepository(Supabase.instance.client);
  }

  return MockEmotionRepository();
});

final emotionTagsProvider = FutureProvider<List<EmotionTag>>((ref) async {
  return ref.watch(emotionRepositoryProvider).fetchEmotionTags();
});

class EmotionComposerController extends Notifier<EmotionComposerState> {
  @override
  EmotionComposerState build() => const EmotionComposerState();

  void selectPrimary(int tagId) {
    state = state.copyWith(
      primaryTagId: tagId,
      secondaryTagIds: state.secondaryTagIds.where((id) => id != tagId).toList(),
      clearError: true,
    );
  }

  void toggleSecondary(int tagId) {
    if (state.primaryTagId == null || state.primaryTagId == tagId) {
      return;
    }

    final current = <int>[...state.secondaryTagIds];
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      if (current.length >= AppConstants.maxSecondaryTags) {
        state = state.copyWith(
          errorMessage: '보조 감정은 최대 ${AppConstants.maxSecondaryTags}개까지 선택할 수 있어요.',
        );
        return;
      }
      current.add(tagId);
    }

    state = state.copyWith(
      secondaryTagIds: current,
      clearError: true,
    );
  }

  void updateContent(String value) {
    state = state.copyWith(
      content: value,
      clearError: true,
    );
  }

  Future<bool> submit() async {
    final primaryTagId = state.primaryTagId;
    if (primaryTagId == null) {
      state = state.copyWith(errorMessage: '대표 감정을 먼저 선택해 주세요.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref.read(emotionRepositoryProvider).createStar(
            primaryTagId: primaryTagId,
            secondaryTagIds: state.secondaryTagIds,
            content: state.content.trim(),
          );
      state = const EmotionComposerState();
      return true;
    } catch (error) {
      state = EmotionComposerState(
        primaryTagId: state.primaryTagId,
        secondaryTagIds: state.secondaryTagIds,
        content: state.content,
        isSubmitting: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}

final emotionComposerProvider = NotifierProvider<
    EmotionComposerController, EmotionComposerState>(
  EmotionComposerController.new,
);

