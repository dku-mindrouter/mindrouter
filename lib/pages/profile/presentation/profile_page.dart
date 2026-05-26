import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constellation/data/constellation_repository.dart';
import '../../constellation/data/supabase_constellation_data_source.dart';
import '../../constellation/domain/star.dart';
import '../../constellation/domain/today_status.dart';
import '../../nudge/data/nudge_repository.dart';
import '../../nudge/data/supabase_nudge_data_source.dart';
import '../../nudge/domain/nudge_mission.dart';
import '../data/profile_repository.dart';
import '../data/supabase_profile_data_source.dart';
import '../domain/avatar_collection_item.dart';
import '../domain/my_stats.dart';
import '../../../shared/widgets/app_panel_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.nickname,
    required this.timezone,
    required this.nextRoute,
    required this.userId,
    required this.onOpenSettings,
    required this.onOpenMission,
    required this.onOpenMyStars,
    required this.isPreviewMode,
    required this.refreshTick,
  });

  final String nickname;
  final String timezone;
  final String nextRoute;
  final String userId;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenMission;
  final VoidCallback onOpenMyStars;
  final bool isPreviewMode;
  final int refreshTick;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_TodayStarPreview> _todayStarFuture;
  late Future<MyStats> _myStatsFuture;
  late Future<NudgeMission> _todayMissionFuture;
  late String _nickname;

  @override
  void initState() {
    super.initState();
    _nickname = widget.nickname;
    _todayStarFuture = _loadTodayStarPreview();
    _myStatsFuture = _loadMyStats();
    _todayMissionFuture = _loadTodayMission();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.isPreviewMode != widget.isPreviewMode) {
      setState(() {
        _nickname = widget.nickname;
        _todayStarFuture = _loadTodayStarPreview();
        _myStatsFuture = _loadMyStats();
        _todayMissionFuture = _loadTodayMission();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '내 별',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _ProfileIconButton(
              icon: Icons.settings_outlined,
              label: '설정 열기',
              onPressed: widget.onOpenSettings,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '오늘 밤 11:28 등록됨',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 24),
        FutureBuilder<MyStats>(
          future: _myStatsFuture,
          builder: (BuildContext context, AsyncSnapshot<MyStats> snapshot) {
            final MyStats stats = snapshot.data ?? MyStats.previewMock();
            return _AvatarXpCard(
              stats: stats,
              onTap: () => _openAvatarProfileSheet(stats),
            );
          },
        ),
        const SizedBox(height: 16),
        AppPanelCard(
          padding: const EdgeInsets.all(22),
          backgroundColor: const Color(0xCC1C1E34),
          borderColor: Colors.white.withValues(alpha: 0.06),
          borderRadius: 28,
          child: FutureBuilder<_TodayStarPreview>(
            future: _todayStarFuture,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<_TodayStarPreview> snapshot,
                ) {
                  final _TodayStarPreview preview =
                      snapshot.data ?? _TodayStarPreview.loading();
                  return _TodayStarCardContent(preview: preview);
                },
          ),
        ),
        const SizedBox(height: 16),
        _ProfileActionCard(
          icon: Icons.auto_awesome_mosaic_outlined,
          title: '내가 띄운 별 모아보기',
          subtitle: '내가 남긴 감정 글과 받은 리액션을 확인하기',
          onTap: widget.onOpenMyStars,
        ),
        const SizedBox(height: 16),
        FutureBuilder<NudgeMission>(
          future: _todayMissionFuture,
          builder:
              (BuildContext context, AsyncSnapshot<NudgeMission> snapshot) {
                final NudgeMission mission =
                    snapshot.data ?? NudgeMission.previewMock();
                final bool isCompleted = mission.isCompleted;
                final bool isStarted = mission.isStarted;
                final String stateHeadline = isCompleted
                    ? '오늘의 미션 완료'
                    : isStarted
                    ? '오늘의 맞춤 미션 진행 중'
                    : '오늘의 맞춤 미션';
                final String stateBadge = isCompleted
                    ? '완료됨'
                    : isStarted
                    ? '진행 중'
                    : '시작 전';
                final Color badgeColor = isCompleted
                    ? const Color(0xFFFBBF24)
                    : isStarted
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF818CF8);
                return Semantics(
                  button: true,
                  label: '$stateHeadline, ${mission.title}',
                  child: InkWell(
                    onTap: widget.onOpenMission,
                    borderRadius: BorderRadius.circular(28),
                    child: AppPanelCard(
                      padding: const EdgeInsets.all(20),
                      gradient: LinearGradient(
                        colors: <Color>[
                          isCompleted
                              ? const Color(0xDD252841)
                              : const Color(0xCC1C1E34),
                          isCompleted
                              ? const Color(0xDD33375A)
                              : const Color(0xCC2A2D4A),
                        ],
                      ),
                      borderColor: badgeColor.withValues(alpha: 0.36),
                      borderRadius: 28,
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color(0xFFFBBF24),
                                  isCompleted
                                      ? Color(0xFFD97706)
                                      : Color(0xFFF97316),
                                ],
                              ),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_rounded
                                  : Icons.wb_sunny_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  stateHeadline,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mission.title,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.76),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: badgeColor.withValues(alpha: 0.32),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        isCompleted
                                            ? Icons.check_circle_rounded
                                            : isStarted
                                            ? Icons.timelapse_rounded
                                            : Icons.flag_rounded,
                                        color: badgeColor,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        stateBadge,
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: isCompleted
                                ? badgeColor
                                : Colors.white.withValues(alpha: 0.72),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
        ),
        const SizedBox(height: 16),
        FutureBuilder<MyStats>(
          future: _myStatsFuture,
          builder: (BuildContext context, AsyncSnapshot<MyStats> snapshot) {
            final MyStats stats = snapshot.data ?? MyStats.previewMock();
            return Row(
              children: <Widget>[
                Expanded(
                  child: _MetricCard(
                    icon: Icons.local_fire_department_outlined,
                    iconColor: const Color(0xFF818CF8),
                    value: '${stats.currentStreak}',
                    label: '연속 기록일',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.coffee_outlined,
                    iconColor: const Color(0xFFFBBF24),
                    value: '${stats.todayReceivedComfortCount}',
                    label: '오늘 받은 위로',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<MyStats>(
          future: _myStatsFuture,
          builder: (BuildContext context, AsyncSnapshot<MyStats> snapshot) {
            final MyStats stats = snapshot.data ?? MyStats.previewMock();
            return _NextBadgeCard(stats: stats);
          },
        ),
        const SizedBox(height: 16),
        _ProfileField(label: 'nickname', value: _nickname),
        _ProfileField(label: 'timezone', value: widget.timezone),
        _ProfileField(label: 'next route', value: widget.nextRoute),
        _ProfileField(label: 'user id', value: widget.userId),
      ],
    );
  }

  ProfileRepository _profileRepository() {
    return ProfileRepository(
      dataSource: SupabaseProfileDataSource(client: Supabase.instance.client),
    );
  }

  Future<void> _openAvatarProfileSheet(MyStats stats) async {
    if (widget.isPreviewMode) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _AvatarProfileSheet(
            initialStats: stats,
            avatars: AvatarCollectionItem.previewList(),
            onEquipAvatar: (_) async {},
          );
        },
      );
      return;
    }

    try {
      final ProfileRepository repository = _profileRepository();
      final List<AvatarCollectionItem> avatars = await repository
          .fetchAvatarCollection();
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _AvatarProfileSheet(
            initialStats: stats,
            avatars: avatars,
            onEquipAvatar: (AvatarCollectionItem avatar) async {
              final String? userAvatarId = avatar.userAvatarId;
              if (userAvatarId == null || !avatar.isUnlocked) {
                return;
              }
              await repository.equipAvatar(userAvatarId: userAvatarId);
              if (mounted) {
                setState(() {
                  _myStatsFuture = _loadMyStats();
                });
              }
            },
          );
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필 정보를 불러오지 못했어요.')));
    }
  }

  Future<MyStats> _loadMyStats() async {
    if (widget.isPreviewMode) {
      return MyStats.previewMock();
    }

    try {
      final ProfileRepository repository = _profileRepository();
      return await repository.fetchMyStats();
    } catch (_) {
      return MyStats.previewMock();
    }
  }

  Future<NudgeMission> _loadTodayMission() async {
    if (widget.isPreviewMode) {
      return NudgeMission.previewMock();
    }

    try {
      final SupabaseClient client = Supabase.instance.client;
      final NudgeRepository repository = NudgeRepository(
        dataSource: SupabaseNudgeDataSource(client: client),
      );
      return await repository.fetchTodayMission();
    } catch (_) {
      return NudgeMission.previewMock();
    }
  }

  Future<_TodayStarPreview> _loadTodayStarPreview() async {
    if (widget.isPreviewMode) {
      return _TodayStarPreview.previewMock();
    }

    try {
      final SupabaseClient client = Supabase.instance.client;
      final ConstellationRepository repository = ConstellationRepository(
        dataSource: SupabaseConstellationDataSource(client: client),
      );

      final TodayStatus status = await repository.fetchTodayStatus();
      if (!status.hasStarToday || status.todayStarId == null) {
        return _TodayStarPreview.empty();
      }

      final Star star = await repository.fetchStarById(status.todayStarId!);
      final String tagLabel = star.tagNames.isNotEmpty
          ? '#${star.tagNames.first}'
          : '#오늘의별';

      return _TodayStarPreview(
        badgeLabel: tagLabel,
        metaLine:
            '${_bucketLabel(star.timeBucket)} · ${_timeText(star.createdAt)}',
        message: star.content,
        stateLabel: status.isStarExpiredToday ? '보관됨' : '등록 완료',
        stateColor: status.isStarExpiredToday
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E),
      );
    } catch (_) {
      return _TodayStarPreview.error();
    }
  }

  String _bucketLabel(String bucket) {
    switch (bucket) {
      case 'dawn':
        return '새벽';
      case 'morning':
        return '아침';
      case 'day':
        return '낮';
      case 'evening':
        return '저녁';
      case 'night':
        return '밤';
      default:
        return '오늘';
    }
  }

  String _timeText(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final int hour = local.hour;
    final int minute = local.minute;
    final bool isAm = hour < 12;
    final int normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final String minuteText = minute.toString().padLeft(2, '0');
    return '${isAm ? '오전' : '오후'} $normalizedHour:$minuteText';
  }
}

class _TodayStarCardContent extends StatelessWidget {
  const _TodayStarCardContent({required this.preview});

  final _TodayStarPreview preview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                const Color(0xFF7656B8).withValues(alpha: 0.92),
                const Color(0xFF7656B8).withValues(alpha: 0.16),
              ],
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x667656B8),
                blurRadius: 34,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              preview.badgeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Text(
                    '오늘의 별',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.auto_awesome, color: Color(0xFFD8B4FE), size: 16),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                preview.metaLine,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                preview.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: preview.stateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: preview.stateColor.withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.circle, color: preview.stateColor, size: 10),
                    const SizedBox(width: 6),
                    Text(
                      preview.stateLabel,
                      style: TextStyle(
                        color: preview.stateColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayStarPreview {
  const _TodayStarPreview({
    required this.badgeLabel,
    required this.metaLine,
    required this.message,
    required this.stateLabel,
    required this.stateColor,
  });

  final String badgeLabel;
  final String metaLine;
  final String message;
  final String stateLabel;
  final Color stateColor;

  factory _TodayStarPreview.loading() {
    return const _TodayStarPreview(
      badgeLabel: '#불러오는중',
      metaLine: '오늘 · 동기화 중',
      message: '내가 등록한 별 내용을 불러오고 있어요.',
      stateLabel: '동기화 중',
      stateColor: Color(0xFF818CF8),
    );
  }

  factory _TodayStarPreview.previewMock() {
    return const _TodayStarPreview(
      badgeLabel: '#평온',
      metaLine: '밤 · 오후 11:28',
      message: '지금은 preview 모드라서 샘플 메시지를 보여주고 있어요.',
      stateLabel: '프리뷰 모드',
      stateColor: Color(0xFF38BDF8),
    );
  }

  factory _TodayStarPreview.empty() {
    return const _TodayStarPreview(
      badgeLabel: '#오늘의별',
      metaLine: '오늘 · 아직 미등록',
      message: '오늘 작성한 별이 아직 없어요. 감정을 기록하고 내 별을 띄워보세요.',
      stateLabel: '작성 전',
      stateColor: Color(0xFFF59E0B),
    );
  }

  factory _TodayStarPreview.error() {
    return const _TodayStarPreview(
      badgeLabel: '#연결오류',
      metaLine: '오늘 · 불러오기 실패',
      message: '내 별 내용을 불러오지 못했어요. 잠시 후 다시 확인해주세요.',
      stateLabel: '오류',
      stateColor: Color(0xFFFB7185),
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  const _ProfileIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.82)),
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AppPanelCard(
        padding: const EdgeInsets.all(20),
        backgroundColor: const Color(0x801C1E34),
        borderColor: const Color(0x336366F1),
        borderRadius: 28,
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF818CF8).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFFC7D2FE)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppPanelCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppPanelCard(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      backgroundColor: const Color(0x801C1E34),
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: Column(
        children: <Widget>[
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarXpCard extends StatelessWidget {
  const _AvatarXpCard({required this.stats, required this.onTap});

  final MyStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isMaxLevel = stats.avatarLevel >= MyStats.maxAvatarLevel;
    final String progressLabel = isMaxLevel
        ? 'MAX'
        : '${stats.avatarXpInCurrentLevel} / ${stats.avatarLevelRange} XP';
    final String nextLabel = isMaxLevel
        ? '최대 레벨 도달'
        : '다음 성장까지 ${stats.avatarRemainingXp} XP';

    return Semantics(
      button: true,
      label: '${stats.avatarNameKo} 아바타 성장 카드',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AppPanelCard(
          padding: const EdgeInsets.all(20),
          backgroundColor: const Color(0x801C1E34),
          borderColor: const Color(0x33818CF8),
          borderRadius: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF38BDF8), Color(0xFF818CF8)],
                      ),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${stats.avatarNameKo} Lv.${stats.avatarLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stats.avatarLevelTitleKo,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${stats.avatarXp} XP',
                    style: const TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.tune_rounded,
                    color: Colors.white.withValues(alpha: 0.52),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stats.avatarLevelProgress,
                  minHeight: 9,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF38BDF8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    progressLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.46),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    nextLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.46),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarProfileSheet extends StatefulWidget {
  const _AvatarProfileSheet({
    required this.initialStats,
    required this.avatars,
    required this.onEquipAvatar,
  });

  final MyStats initialStats;
  final List<AvatarCollectionItem> avatars;
  final Future<void> Function(AvatarCollectionItem avatar) onEquipAvatar;

  @override
  State<_AvatarProfileSheet> createState() => _AvatarProfileSheetState();
}

class _AvatarProfileSheetState extends State<_AvatarProfileSheet> {
  late List<AvatarCollectionItem> _avatars;
  String? _message;

  @override
  void initState() {
    super.initState();
    _avatars = widget.avatars;
  }

  @override
  Widget build(BuildContext context) {
    final int totalXp = _avatars.isEmpty
        ? widget.initialStats.avatarXp
        : _avatars.first.totalCollectionXp;
    final int totalLevel = _avatars.isEmpty
        ? widget.initialStats.avatarLevel
        : _avatars.first.totalCollectionLevel;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.56,
      maxChildSize: 0.94,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121427),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      '아바타 프로필',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SheetSummaryCard(
                      label: '총 경험치',
                      value: '$totalXp XP',
                      icon: Icons.bolt_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetSummaryCard(
                      label: '아바타 레벨 합',
                      value: '$totalLevel',
                      icon: Icons.stacked_line_chart_rounded,
                    ),
                  ),
                ],
              ),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const Text(
                '아바타 선택',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ..._avatars.map(_buildAvatarTile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarTile(AvatarCollectionItem avatar) {
    final Color accent = avatar.isUnlocked
        ? const Color(0xFF38BDF8)
        : Colors.white.withValues(alpha: 0.28);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: avatar.isUnlocked ? () => _equipAvatar(avatar) : null,
        borderRadius: BorderRadius.circular(22),
        child: AppPanelCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: avatar.isEquipped
              ? const Color(0x2238BDF8)
              : Colors.white.withValues(alpha: 0.04),
          borderColor: avatar.isEquipped
              ? const Color(0x6638BDF8)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: accent.withValues(alpha: 0.18),
                    ),
                    child: Icon(
                      avatar.isUnlocked
                          ? Icons.pets_rounded
                          : Icons.lock_outline_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          avatar.avatarNameKo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          avatar.isUnlocked
                              ? 'Lv.${avatar.level} · ${avatar.xp} XP'
                              : '아직 잠긴 아바타',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (avatar.isEquipped)
                    const _AvatarBadge(label: '장착 중')
                  else if (avatar.isUnlocked)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white54,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                avatar.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (avatar.isUnlocked) ...<Widget>[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: avatar.levelProgress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _equipAvatar(AvatarCollectionItem avatar) async {
    if (avatar.isEquipped) {
      return;
    }
    try {
      await widget.onEquipAvatar(avatar);
      setState(() {
        _avatars = _avatars
            .map(
              (AvatarCollectionItem item) => AvatarCollectionItem(
                avatarId: item.avatarId,
                userAvatarId: item.userAvatarId,
                avatarCode: item.avatarCode,
                avatarNameKo: item.avatarNameKo,
                description: item.description,
                rarity: item.rarity,
                isUnlocked: item.isUnlocked,
                isEquipped: item.userAvatarId == avatar.userAvatarId,
                level: item.level,
                xp: item.xp,
                levelTitleKo: item.levelTitleKo,
                currentLevelXp: item.currentLevelXp,
                nextLevelXp: item.nextLevelXp,
                totalCollectionXp: item.totalCollectionXp,
                totalCollectionLevel: item.totalCollectionLevel,
              ),
            )
            .toList(growable: false);
        _message = '${avatar.avatarNameKo}을(를) 장착했어요.';
      });
    } catch (_) {
      setState(() {
        _message = '아바타를 변경하지 못했어요.';
      });
    }
  }
}

class _SheetSummaryCard extends StatelessWidget {
  const _SheetSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPanelCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: const Color(0x1AFDE68A),
      borderColor: const Color(0x33FDE68A),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: const Color(0xFFFDE68A), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x6638BDF8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFBAE6FD),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NextBadgeCard extends StatelessWidget {
  const _NextBadgeCard({required this.stats});

  final MyStats stats;

  @override
  Widget build(BuildContext context) {
    final int remainingDays = (MyStats.nextBadgeGoal - stats.currentStreak)
        .clamp(0, MyStats.nextBadgeGoal);

    return AppPanelCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: const Color(0x801C1E34),
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '다음 뱃지까지 $remainingDays일',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFDE68A),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stats.nextBadgeProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7C3AED),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Text(
                '연속',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.44),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.currentStreak} / ${MyStats.nextBadgeGoal} 연속일',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.44),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
