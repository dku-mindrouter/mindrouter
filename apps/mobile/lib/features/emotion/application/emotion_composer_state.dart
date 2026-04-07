class EmotionComposerState {
  const EmotionComposerState({
    this.primaryTagId,
    this.secondaryTagIds = const <int>[],
    this.content = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  final int? primaryTagId;
  final List<int> secondaryTagIds;
  final String content;
  final bool isSubmitting;
  final String? errorMessage;

  bool get canSubmit => primaryTagId != null && !isSubmitting;

  EmotionComposerState copyWith({
    int? primaryTagId,
    List<int>? secondaryTagIds,
    String? content,
    bool? isSubmitting,
    String? errorMessage,
    bool clearPrimary = false,
    bool clearError = false,
  }) {
    return EmotionComposerState(
      primaryTagId: clearPrimary ? null : primaryTagId ?? this.primaryTagId,
      secondaryTagIds: secondaryTagIds ?? this.secondaryTagIds,
      content: content ?? this.content,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

