import 'package:flutter/material.dart';

import '../../../shared/widgets/app_panel_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.nickname,
    required this.timezone,
    required this.nextRoute,
    required this.userId,
    required this.onOpenSettings,
    required this.onOpenMission,
  });

  final String nickname;
  final String timezone;
  final String nextRoute;
  final String userId;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenMission;

  @override
  Widget build(BuildContext context) {
    const List<_WeeklyMoodBarData> weeklyMood = <_WeeklyMoodBarData>[
      _WeeklyMoodBarData(day: '월', value: 3, color: Color(0xFF7656B8)),
      _WeeklyMoodBarData(day: '화', value: 5, color: Color(0xFF683F99)),
      _WeeklyMoodBarData(day: '수', value: 4, color: Color(0xFF7656B8)),
      _WeeklyMoodBarData(day: '목', value: 6, color: Color(0xFF9B4F60)),
      _WeeklyMoodBarData(day: '금', value: 4, color: Color(0xFF599B8E)),
      _WeeklyMoodBarData(day: '토', value: 2, color: Color(0xFFB37D4E)),
      _WeeklyMoodBarData(day: '오늘', value: 7, color: Color(0xFF7656B8)),
    ];

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
              onPressed: onOpenSettings,
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
        AppPanelCard(
          padding: const EdgeInsets.all(22),
          backgroundColor: const Color(0xCC1C1E34),
          borderColor: Colors.white.withValues(alpha: 0.06),
          borderRadius: 28,
          child: Row(
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
                child: const Center(
                  child: Text(
                    '#지침',
                    style: TextStyle(
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
                        Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFD8B4FE),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '밤 11:28 · 혼자 시간',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1AF59E0B),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x33F59E0B)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFBBF24),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '번아웃 주의',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
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
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: '오늘의 맞춤 미션, 햇살과 함께 10분 걷기',
          child: InkWell(
            onTap: onOpenMission,
            borderRadius: BorderRadius.circular(28),
            child: AppPanelCard(
              padding: const EdgeInsets.all(20),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xCC1C1E34), Color(0xCC2A2D4A)],
              ),
              borderColor: const Color(0x336366F1),
              borderRadius: 28,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      gradient: LinearGradient(
                        colors: <Color>[Color(0xFFFBBF24), Color(0xFFF97316)],
                      ),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          '오늘의 맞춤 미션',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '햇살과 함께 10분 걷기',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department_outlined,
                iconColor: Color(0xFF818CF8),
                value: '7',
                label: '연속 기록일',
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                icon: Icons.coffee_outlined,
                iconColor: Color(0xFFFBBF24),
                value: '3',
                label: '오늘 받은 위로',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _WeeklyMoodChart(data: weeklyMood),
        const SizedBox(height: 16),
        const _NextBadgeCard(),
        const SizedBox(height: 16),
        _ProfileField(label: 'nickname', value: nickname),
        _ProfileField(label: 'timezone', value: timezone),
        _ProfileField(label: 'next route', value: nextRoute),
        _ProfileField(label: 'user id', value: userId),
      ],
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

class _WeeklyMoodChart extends StatelessWidget {
  const _WeeklyMoodChart({required this.data});

  final List<_WeeklyMoodBarData> data;

  @override
  Widget build(BuildContext context) {
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
                'Recent 7 Days',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '감정 강도',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data
                  .map(
                    (_WeeklyMoodBarData item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              height: 14 * item.value.toDouble(),
                              decoration: BoxDecoration(
                                color: item.color.withValues(
                                  alpha: item.day == '오늘' ? 1 : 0.62,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.day,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.46),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBadgeCard extends StatelessWidget {
  const _NextBadgeCard();

  @override
  Widget build(BuildContext context) {
    return AppPanelCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: const Color(0x801C1E34),
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Text(
                '다음 뱃지까지 3일',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.auto_awesome, color: Color(0xFFFDE68A), size: 16),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                '연속일',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.44),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '7 / 10 streak days',
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

class _WeeklyMoodBarData {
  const _WeeklyMoodBarData({
    required this.day,
    required this.value,
    required this.color,
  });

  final String day;
  final int value;
  final Color color;
}
