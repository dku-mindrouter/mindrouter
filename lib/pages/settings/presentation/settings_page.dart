import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_panel_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _nightStarEnabled = true;
  bool _morningMissionEnabled = true;
  bool _comfortArrivalEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x990A0B14)),
              ),
            ),
          ),
        ),
        ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                _RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  label: '프로필로 돌아가기',
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 18),
                Text(
                  '설정',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SettingsSectionHeader(
              icon: Icons.notifications_none_rounded,
              label: '알림 설정',
            ),
            const SizedBox(height: 14),
            AppPanelCard(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xD91A1B2F),
              borderColor: Colors.white.withValues(alpha: 0.07),
              borderRadius: 28,
              child: Column(
                children: <Widget>[
                  _NotificationSettingTile(
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF7C83FF),
                    title: '매일 밤 나의 별 띄우기',
                    description: '하루를 마무리할 시간을 알려드려요',
                    timeLabel: '오후 11:00',
                    value: _nightStarEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _nightStarEnabled = value;
                      });
                    },
                  ),
                  const _SettingsDivider(),
                  _NotificationSettingTile(
                    icon: Icons.wb_sunny_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: '아침 맞춤 미션',
                    description: '하루의 시작을 돕는 가벼운 제안',
                    timeLabel: '오전 08:00',
                    value: _morningMissionEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _morningMissionEnabled = value;
                      });
                    },
                  ),
                  const _SettingsDivider(),
                  _NotificationSettingTile(
                    icon: Icons.favorite_border_rounded,
                    iconColor: const Color(0xFFFF4F7B),
                    title: '새로운 위로 도착',
                    description: '누군가 내 별에 따뜻한 마음을 남겼을 때',
                    value: _comfortArrivalEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _comfortArrivalEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const _SettingsSectionHeader(
              icon: Icons.settings_outlined,
              label: '앱 환경',
            ),
            const SizedBox(height: 14),
            AppPanelCard(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xD91A1B2F),
              borderColor: Colors.white.withValues(alpha: 0.07),
              borderRadius: 28,
              child: _SettingsToggleTile(
                icon: Icons.dark_mode_outlined,
                iconColor: const Color(0xFF8090C8),
                title: '다크 모드 고정',
                description: '앱 전체가 다크 모드로 고정되어 있어요',
                value: true,
                onChanged: null,
              ),
            ),
            const SizedBox(height: 30),
            AppPanelCard(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xD91A1B2F),
              borderColor: Colors.white.withValues(alpha: 0.07),
              borderRadius: 28,
              child: Column(
                children: <Widget>[
                  _SettingsActionTile(
                    icon: Icons.logout_rounded,
                    title: '로그아웃',
                    color: Colors.white.withValues(alpha: 0.86),
                    onTap: () =>
                        _showPlaceholder('익명 로그인 정책이 확정되면 로그아웃 동작을 연결할 예정이에요.'),
                  ),
                  const _SettingsDivider(),
                  _SettingsActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: '계정 탈퇴',
                    color: const Color(0xFFFF5578),
                    onTap: () =>
                        _showPlaceholder('계정 탈퇴는 서버 데이터 삭제 정책 확정 후 연결할 예정이에요.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 72),
            Center(
              child: Text(
                'Mind Router v1.0.0',
                style: TextStyle(
                  color: const Color(0xFF8AA0C6).withValues(alpha: 0.58),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B1D32),
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

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF8AA0C6), size: 17),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8AA0C6),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _NotificationSettingTile extends StatelessWidget {
  const _NotificationSettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.timeLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? timeLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      child: Row(
        children: <Widget>[
          _SettingIcon(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _SettingsSwitch(value: value, onChanged: onChanged),
              if (timeLabel != null) ...<Widget>[
                const SizedBox(height: 8),
                _TimePill(label: timeLabel!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      child: Row(
        children: <Widget>[
          _SettingIcon(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SettingsSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.schedule_rounded,
            color: Colors.white.withValues(alpha: 0.76),
            size: 15,
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFF6558FF),
      inactiveThumbColor: const Color(0xFF9CA3AF),
      inactiveTrackColor: const Color(0xFF39386E),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}
