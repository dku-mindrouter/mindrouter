const Set<String> _draftEmotionBlockedWords = <String>{
  'fuck',
  'shit',
  'bitch',
  'asshole',
  '시발',
  '씨발',
  '병신',
  '꺼져',
  '죽어',
};

bool checkRiskExpression({required String content}) {
  final String lowered = content.trim().toLowerCase();
  for (final String blockedWord in _draftEmotionBlockedWords) {
    if (lowered.contains(blockedWord)) {
      return true;
    }
  }
  return false;
}
