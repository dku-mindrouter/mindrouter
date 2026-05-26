import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/app_panel_card.dart';
import '../../nudge/data/nudge_repository.dart';
import '../../nudge/data/supabase_nudge_data_source.dart';
import '../../nudge/domain/nudge_exception.dart';
import '../../nudge/domain/nudge_mission.dart';

class TodayMissionPage extends StatefulWidget {
  const TodayMissionPage({
    super.key,
    required this.onBack,
    required this.isPreviewMode,
  });

  final VoidCallback onBack;
  final bool isPreviewMode;

  @override
  State<TodayMissionPage> createState() => _TodayMissionPageState();
}

class _TodayMissionPageState extends State<TodayMissionPage> {
  late final NudgeRepository _repository = NudgeRepository(
    dataSource: SupabaseNudgeDataSource(client: Supabase.instance.client),
  );

  late Future<NudgeMission> _future = _fetchMission();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NudgeMission>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<NudgeMission> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF818CF8)),
          );
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 160),
            children: <Widget>[
              _Header(onBack: widget.onBack),
              const SizedBox(height: 34),
              AppPanelCard(
                backgroundColor: const Color(0xE51B1D34),
                borderColor: Colors.white.withValues(alpha: 0.08),
                borderRadius: 28,
                child: Text(
                  _mapErrorToMessage(snapshot.error),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );
        }

        final NudgeMission mission =
            snapshot.data ?? NudgeMission.previewMock();

        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 160),
          children: <Widget>[
            _Header(onBack: widget.onBack),
            const SizedBox(height: 34),
            _MissionHero(mission: mission),
            const SizedBox(height: 34),
            Text(
              mission.body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 16,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 34),
            _MissionStateCard(mission: mission),
            const SizedBox(height: 18),
            _MissionActionButton(
              isSubmitting: _isSubmitting,
              mission: mission,
              onPressed: () => _handleMissionAction(mission),
            ),
          ],
        );
      },
    );
  }

  Future<NudgeMission> _fetchMission() async {
    if (widget.isPreviewMode) {
      return NudgeMission.previewMock();
    }
    final NudgeMission mission = await _repository.fetchTodayMission(
      markOpened: true,
    );
    return mission;
  }

  Future<void> _handleMissionAction(NudgeMission mission) async {
    if (widget.isPreviewMode) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프리뷰 모드에서는 미션 상태를 저장하지 않아요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1B1D32),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (mission.isStarted) {
        await _repository.completeTodayMission(deliveryId: mission.deliveryId);
      } else {
        await _repository.startTodayMission(deliveryId: mission.deliveryId);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _future = _fetchMission();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapErrorToMessage(error)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B1D32),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _mapErrorToMessage(Object? error) {
    if (error is NudgeException) {
      switch (error.code) {
        case NudgeErrorCode.nudgeNotFound:
          return '오늘의 미션을 찾을 수 없어요.';
        case NudgeErrorCode.unauthorized:
          return '로그인 상태를 다시 확인해 주세요.';
        case NudgeErrorCode.forbidden:
          return '오늘의 미션을 불러올 권한이 없어요.';
      }
    }
    return '오늘의 미션을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.';
  }
}

class _MissionActionButton extends StatelessWidget {
  const _MissionActionButton({
    required this.isSubmitting,
    required this.mission,
    required this.onPressed,
  });

  final bool isSubmitting;
  final NudgeMission mission;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isSubmitting || mission.isCompleted ? null : onPressed,
      icon: Icon(
        mission.isStarted ? Icons.check_rounded : Icons.play_arrow_rounded,
        size: 26,
      ),
      label: Text(mission.actionLabel),
      style:
          FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A0C),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.42),
            padding: const EdgeInsets.symmetric(vertical: 19),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            backgroundColor: const WidgetStatePropertyAll<Color>(
              Color(0xFFFF7A0C),
            ),
          ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          label: '프로필로 돌아가기',
          onPressed: onBack,
        ),
        const Expanded(
          child: Center(
            child: Text(
              "TODAY'S MISSION",
              style: TextStyle(
                color: Color(0xFFD6DBEA),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _MissionHero extends StatelessWidget {
  const _MissionHero({required this.mission});

  final NudgeMission mission;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                _colorForToken(mission.accentStartColor),
                _colorForToken(mission.accentEndColor),
              ],
            ),
          ),
          child: Icon(
            _iconForToken(mission.accentIcon),
            color: Colors.white,
            size: 31,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                mission.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mission.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionStateCard extends StatelessWidget {
  const _MissionStateCard({required this.mission});

  final NudgeMission mission;

  @override
  Widget build(BuildContext context) {
    return AppPanelCard(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      borderColor: Colors.white.withValues(alpha: 0.08),
      borderRadius: 24,
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(
              mission.isCompleted
                  ? Icons.check_circle_outline_rounded
                  : mission.isStarted
                  ? Icons.timelapse_rounded
                  : Icons.flag_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  mission.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.isCompleted
                      ? '오늘의 미션을 완료했어요. 내일 새로운 미션이 도착합니다.'
                      : mission.isStarted
                      ? '지금 진행 중인 미션이에요. 끝나면 완료 버튼을 눌러 주세요.'
                      : '아직 시작 전이에요. 준비되면 버튼을 눌러 시작하세요.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.86)),
        ),
      ),
    );
  }
}

IconData _iconForToken(String icon) {
  switch (icon) {
    case 'air':
      return Icons.air_rounded;
    case 'chat_bubble_outline_rounded':
      return Icons.chat_bubble_outline_rounded;
    case 'directions_walk_rounded':
      return Icons.directions_walk_rounded;
    case 'edit_note_rounded':
      return Icons.edit_note_rounded;
    case 'inventory_2_outlined':
      return Icons.inventory_2_outlined;
    case 'landscape_outlined':
      return Icons.landscape_outlined;
    case 'local_cafe_outlined':
      return Icons.local_cafe_outlined;
    case 'music_note_rounded':
      return Icons.music_note_rounded;
    case 'notifications_off_outlined':
      return Icons.notifications_off_outlined;
    case 'schedule_send_outlined':
      return Icons.schedule_send_outlined;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'task_alt_rounded':
      return Icons.task_alt_rounded;
    case 'visibility_rounded':
      return Icons.visibility_rounded;
    case 'water_drop_outlined':
      return Icons.water_drop_outlined;
    case 'wash_rounded':
      return Icons.wash_rounded;
    case 'wb_sunny_outlined':
    default:
      return Icons.wb_sunny_outlined;
  }
}

Color _colorForToken(String color) {
  switch (color) {
    case 'sky':
      return const Color(0xFF38BDF8);
    case 'violet':
      return const Color(0xFF818CF8);
    case 'indigo':
      return const Color(0xFFA5B4FC);
    case 'orange':
      return const Color(0xFFFF720D);
    case 'rose':
      return const Color(0xFFFB7185);
    case 'amber':
    default:
      return const Color(0xFFFFC02B);
  }
}
