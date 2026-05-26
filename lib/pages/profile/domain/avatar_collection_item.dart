class AvatarCollectionItem {
  const AvatarCollectionItem({
    required this.avatarId,
    required this.userAvatarId,
    required this.avatarCode,
    required this.avatarNameKo,
    required this.description,
    required this.rarity,
    required this.isUnlocked,
    required this.isEquipped,
    required this.level,
    required this.xp,
    required this.levelTitleKo,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.totalCollectionXp,
    required this.totalCollectionLevel,
  });

  final int avatarId;
  final String? userAvatarId;
  final String avatarCode;
  final String avatarNameKo;
  final String description;
  final String rarity;
  final bool isUnlocked;
  final bool isEquipped;
  final int level;
  final int xp;
  final String levelTitleKo;
  final int currentLevelXp;
  final int nextLevelXp;
  final int totalCollectionXp;
  final int totalCollectionLevel;

  int get levelRange {
    return nextLevelXp - currentLevelXp;
  }

  int get xpInCurrentLevel {
    return (xp - currentLevelXp).clamp(0, levelRange);
  }

  double get levelProgress {
    if (!isUnlocked) {
      return 0;
    }
    if (level >= 10 || levelRange <= 0) {
      return 1;
    }
    return (xpInCurrentLevel / levelRange).clamp(0, 1).toDouble();
  }

  factory AvatarCollectionItem.fromMap(Map<String, dynamic> map) {
    return AvatarCollectionItem(
      avatarId: (map['avatar_id'] as num?)?.toInt() ?? 0,
      userAvatarId: map['user_avatar_id'] as String?,
      avatarCode: map['avatar_code'] as String? ?? '',
      avatarNameKo: map['avatar_name_ko'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rarity: map['rarity'] as String? ?? 'common',
      isUnlocked: map['is_unlocked'] as bool? ?? false,
      isEquipped: map['is_equipped'] as bool? ?? false,
      level: (map['level'] as num?)?.toInt() ?? 0,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      levelTitleKo: map['level_title_ko'] as String? ?? '',
      currentLevelXp: (map['current_level_xp'] as num?)?.toInt() ?? 0,
      nextLevelXp: (map['next_level_xp'] as num?)?.toInt() ?? 0,
      totalCollectionXp: (map['total_collection_xp'] as num?)?.toInt() ?? 0,
      totalCollectionLevel:
          (map['total_collection_level'] as num?)?.toInt() ?? 0,
    );
  }

  static List<AvatarCollectionItem> previewList() {
    return const <AvatarCollectionItem>[
      AvatarCollectionItem(
        avatarId: 1,
        userAvatarId: 'preview-moon-rabbit',
        avatarCode: 'moon_rabbit',
        avatarNameKo: '달토끼',
        description: '매일의 감정을 조용히 모아 성장하는 기본 아바타',
        rarity: 'common',
        isUnlocked: true,
        isEquipped: true,
        level: 4,
        xp: 360,
        levelTitleKo: '자라나는 빛',
        currentLevelXp: 320,
        nextLevelXp: 500,
        totalCollectionXp: 360,
        totalCollectionLevel: 5,
      ),
      AvatarCollectionItem(
        avatarId: 2,
        userAvatarId: 'preview-sunny-chick',
        avatarCode: 'sunny_chick',
        avatarNameKo: '햇살 병아리',
        description: '행복한 순간을 오래 품고 자라는 아바타',
        rarity: 'common',
        isUnlocked: true,
        isEquipped: false,
        level: 1,
        xp: 0,
        levelTitleKo: '처음 만난 마음',
        currentLevelXp: 0,
        nextLevelXp: 80,
        totalCollectionXp: 360,
        totalCollectionLevel: 5,
      ),
      AvatarCollectionItem(
        avatarId: 3,
        userAvatarId: null,
        avatarCode: 'star_whale',
        avatarNameKo: '별고래',
        description: '긴 기록을 따라 천천히 커지는 수집형 아바타',
        rarity: 'rare',
        isUnlocked: false,
        isEquipped: false,
        level: 0,
        xp: 0,
        levelTitleKo: '잠김',
        currentLevelXp: 0,
        nextLevelXp: 0,
        totalCollectionXp: 360,
        totalCollectionLevel: 5,
      ),
    ];
  }
}
