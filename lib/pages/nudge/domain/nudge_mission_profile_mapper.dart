import 'nudge_exception.dart';

String mapSelectedEmotionToMissionProfile({required String emotionGroup}) {
  final String normalized = emotionGroup.trim().toLowerCase();
  if (normalized.isEmpty) {
    throw const NudgeException(NudgeErrorCode.invalidArgument);
  }

  if (<String>{
    'happy',
    'happiness',
    'joy',
    'pleased',
    '행복',
    '행복함',
    '기쁨',
  }.contains(normalized)) {
    return 'happy';
  }

  if (<String>{
    'energized',
    'energy',
    'active',
    'vitality',
    '활력',
    '기대감',
    '기대감/활력',
    '에너지',
    'positive',
  }.contains(normalized)) {
    return 'energized';
  }

  if (<String>{
    'calm',
    'peaceful',
    'stable',
    'calm_recovery',
    '평온',
    '잔잔함',
    '안정',
  }.contains(normalized)) {
    return 'calm';
  }

  if (<String>{
    'depressed',
    'sad',
    'negative',
    '우울',
    '가라앉음',
  }.contains(normalized)) {
    return 'depressed';
  }

  if (<String>{
    'lethargic',
    'low_energy',
    'burnout',
    'exhausted',
    '지침',
    '무기력',
    '번아웃',
  }.contains(normalized)) {
    return 'lethargic';
  }

  if (<String>{
    'anxious',
    'anxiety',
    'support_need',
    '불안',
    '초조',
    '조급',
  }.contains(normalized)) {
    return 'anxious';
  }

  if (<String>{
    'irritated',
    'irritable',
    'anger',
    '예민',
    '짜증',
    '과자극',
  }.contains(normalized)) {
    return 'irritated';
  }

  throw const NudgeException(NudgeErrorCode.invalidArgument);
}
