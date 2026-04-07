import 'emotion_tag.dart';
import 'my_stats.dart';
import 'nudge.dart';
import 'reaction_type.dart';
import 'star.dart';

const emotionTags = <EmotionTag>[
  EmotionTag(id: 1, nameKo: '공허함', groupName: 'low_energy'),
  EmotionTag(id: 2, nameKo: '지침', groupName: 'low_energy'),
  EmotionTag(id: 3, nameKo: '무기력', groupName: 'low_energy'),
  EmotionTag(id: 4, nameKo: '잔잔함', groupName: 'recovery'),
  EmotionTag(id: 5, nameKo: '안도', groupName: 'recovery'),
  EmotionTag(id: 6, nameKo: '불안', groupName: 'anxious'),
  EmotionTag(id: 7, nameKo: '외로움', groupName: 'isolation'),
];

const reactionTypes = <ReactionType>[
  ReactionType(id: 1, code: 'tea', labelKo: '따뜻한 차', icon: '☕'),
  ReactionType(id: 2, code: 'hug', labelKo: '안아드려요', icon: '🫂'),
  ReactionType(id: 3, code: 'thanks', labelKo: '고생했어요', icon: '✨'),
  ReactionType(id: 4, code: 'together', labelKo: '함께해요', icon: '🌙'),
];

final mockStars = <Star>[
  Star(
    id: 'star-1',
    primaryTag: '공허함',
    content: '새벽에도 불이 켜져 있었어요.',
    timeBucket: '밤',
    reactionCount: 3,
    relationScore: 85,
    createdAt: DateTime(2026, 4, 7, 2, 24),
  ),
  Star(
    id: 'star-2',
    primaryTag: '잔잔함',
    content: '오늘은 숨이 조금 덜 가빴어요.',
    timeBucket: '아침',
    reactionCount: 1,
    relationScore: 61,
    createdAt: DateTime(2026, 4, 7, 8, 10),
  ),
];

const mockNudges = <Nudge>[
  Nudge(
    id: 'nudge-1',
    title: '오늘의 심리 스니펫',
    body: '무기력한 날에는 할 일을 줄이는 것도 회복의 방식일 수 있어요.',
    type: 'snippet',
  ),
  Nudge(
    id: 'nudge-2',
    title: '따뜻한 반응이 도착했어요',
    body: '어젯밤 3명이 당신의 별을 따뜻하게 바라봤어요.',
    type: 'reaction_received',
  ),
];

const mockStats = MyStats(
  streakDays: 7,
  receivedReactionCount: 3,
  recentEmotionCounts: <String, int>{
    '월': 2,
    '화': 1,
    '수': 3,
    '목': 2,
    '금': 4,
    '토': 4,
    '오늘': 5,
  },
);

