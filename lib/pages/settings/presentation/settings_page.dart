import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/push_notification_registrar.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/supabase_profile_data_source.dart';
import '../../../shared/widgets/app_panel_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.onBack,
    required this.userId,
    required this.nickname,
    required this.isPreviewMode,
    required this.onNicknameChanged,
    this.notificationRegistrar,
  });

  final VoidCallback onBack;
  final String userId;
  final String nickname;
  final bool isPreviewMode;
  final ValueChanged<String> onNicknameChanged;
  final PushNotificationRegistrar? notificationRegistrar;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushEnabled = false;
  bool _isLoadingPushPermission = true;
  bool _nightStarEnabled = true;
  bool _morningMissionEnabled = true;
  bool _comfortArrivalEnabled = true;
  late final TextEditingController _nicknameController;
  bool _isSavingNickname = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.nickname);
    _loadPushPermissionState();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nickname != widget.nickname &&
        _nicknameController.text != widget.nickname) {
      _nicknameController.text = widget.nickname;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

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
              icon: Icons.person_outline_rounded,
              label: '프로필 설정',
            ),
            const SizedBox(height: 14),
            AppPanelCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: const Color(0xD91A1B2F),
              borderColor: Colors.white.withValues(alpha: 0.07),
              borderRadius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '닉네임 변경',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '2~24자, 공백 없이 사용할 수 있어요.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nicknameController,
                    maxLength: 24,
                    enabled: !_isSavingNickname,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                      ),
                      hintText: '닉네임 입력',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFF818CF8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSavingNickname ? null : _saveNickname,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF39386E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(_isSavingNickname ? '저장 중' : '닉네임 저장'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
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
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFF38BDF8),
                    title: '푸시 알림 받기',
                    description: _pushPermissionDescription,
                    value: _pushEnabled,
                    isBusy: _isLoadingPushPermission,
                    onChanged: _handlePushPermissionChanged,
                  ),
                  const _SettingsDivider(),
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

  Future<void> _saveNickname() async {
    final String nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 24 || nickname.contains(' ')) {
      _showPlaceholder('닉네임은 2~24자, 공백 없이 입력해 주세요.');
      return;
    }

    if (nickname == widget.nickname) {
      _showPlaceholder('이미 사용 중인 닉네임이에요.');
      return;
    }

    setState(() {
      _isSavingNickname = true;
    });

    try {
      final String updatedNickname;
      if (widget.isPreviewMode) {
        updatedNickname = nickname;
      } else {
        final ProfileRepository repository = ProfileRepository(
          dataSource: SupabaseProfileDataSource(
            client: Supabase.instance.client,
          ),
        );
        updatedNickname = await repository.updateNickname(nickname: nickname);
      }

      if (!mounted) {
        return;
      }
      _nicknameController.text = updatedNickname;
      widget.onNicknameChanged(updatedNickname);
      _showPlaceholder('닉네임을 변경했어요.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showPlaceholder('닉네임을 변경하지 못했어요. 중복이거나 사용할 수 없는 값일 수 있어요.');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNickname = false;
        });
      }
    }
  }

  String get _pushPermissionDescription {
    if (_isLoadingPushPermission) {
      return '알림 권한 상태를 확인하고 있어요';
    }
    if (_pushEnabled) {
      return '리액션과 편지 도착 알림을 받을 수 있어요';
    }
    return '켜면 기기 권한 요청 후 알림을 받을 수 있어요';
  }

  Future<void> _loadPushPermissionState() async {
    final PushNotificationRegistrar? registrar = widget.notificationRegistrar;
    if (registrar == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pushEnabled = false;
        _isLoadingPushPermission = false;
      });
      return;
    }

    final bool isGranted = await registrar.isEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _pushEnabled = isGranted;
      _isLoadingPushPermission = false;
    });
  }

  Future<void> _handlePushPermissionChanged(bool value) async {
    final PushNotificationRegistrar? registrar = widget.notificationRegistrar;
    if (registrar == null || _isLoadingPushPermission) {
      return;
    }

    setState(() {
      _isLoadingPushPermission = true;
    });

    try {
      if (value) {
        final bool isGranted = await registrar
            .requestPermissionAndRegisterForUser(userId: widget.userId);
        if (!mounted) {
          return;
        }
        setState(() {
          _pushEnabled = isGranted;
        });
        if (!isGranted) {
          _showPlaceholder('기기 알림 권한이 꺼져 있어요. 시스템 설정에서 알림을 허용해 주세요.');
        }
      } else {
        await registrar.disableForUser(userId: widget.userId);
        if (!mounted) {
          return;
        }
        setState(() {
          _pushEnabled = false;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showPlaceholder('알림 설정을 변경하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPushPermission = false;
        });
      }
    }
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
    this.isBusy = false,
    this.timeLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? timeLabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isBusy;

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
              if (isBusy)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF818CF8),
                  ),
                )
              else
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
