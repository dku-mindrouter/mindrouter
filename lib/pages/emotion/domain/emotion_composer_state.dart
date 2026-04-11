class EmotionComposerState {
  const EmotionComposerState({this.selectedTagIds = const <int>[]});

  final List<int> selectedTagIds;

  EmotionComposerState copyWith({List<int>? selectedTagIds}) {
    return EmotionComposerState(
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    );
  }
}
