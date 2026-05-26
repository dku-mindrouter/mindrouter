String mapEmotionGroup({required String tagNameKo}) {
  final String normalized = tagNameKo.trim();

  if (normalized.isEmpty) {
    return 'neutral';
  }

  if (_happyEmotionTags.contains(normalized)) {
    return 'happy';
  }
  if (_positiveEmotionTags.contains(normalized)) {
    return 'positive';
  }
  if (_negativeEmotionTags.contains(normalized)) {
    return 'negative';
  }
  if (_anxiousEmotionTags.contains(normalized)) {
    return 'anxious';
  }
  if (_calmEmotionTags.contains(normalized)) {
    return 'calm';
  }
  return 'neutral';
}

const Set<String> _happyEmotionTags = <String>{'행복함', '행복'};

const Set<String> _positiveEmotionTags = <String>{'기대감/활력'};

const Set<String> _negativeEmotionTags = <String>{
  '우울함',
  '지침/무기력',
  '예민함/짜증',
};

const Set<String> _anxiousEmotionTags = <String>{'불안함'};

const Set<String> _calmEmotionTags = <String>{
  '평온함',
  '평온함/잔잔함',
  '잔잔함',
};
