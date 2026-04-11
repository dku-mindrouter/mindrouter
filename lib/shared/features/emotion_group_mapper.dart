String mapEmotionGroup({required String tagNameKo}) {
  final String normalized = tagNameKo.trim();

  if (normalized.isEmpty) {
    return 'neutral';
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

const Set<String> _positiveEmotionTags = <String>{
  '기쁨',
  '행복',
  '설렘',
  '감사',
  '뿌듯함',
};

const Set<String> _negativeEmotionTags = <String>{
  '분노',
  '짜증',
  '우울',
  '슬픔',
  '상처',
};

const Set<String> _anxiousEmotionTags = <String>{
  '불안',
  '긴장',
  '걱정',
  '초조',
  '두려움',
};

const Set<String> _calmEmotionTags = <String>{
  '평온',
  '안정',
  '무난',
  '담담',
};
