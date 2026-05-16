import 'package:flutter/material.dart';

import '../pages/comfort/presentation/comfort_page.dart';
import '../pages/constellation/presentation/constellation_page.dart';
import '../pages/emotion/presentation/emotion_home_page.dart';
import '../pages/profile/presentation/profile_page.dart';
import '../pages/profile/presentation/today_mission_page.dart';
import '../pages/settings/presentation/settings_page.dart';
import '../shared/widgets/space_backdrop.dart';

class FigmaWireframeExperience extends StatefulWidget {
  const FigmaWireframeExperience({
    super.key,
    required this.userId,
    required this.nickname,
    required this.timezone,
    required this.nextRoute,
    this.previewMessage,
  });

  final String userId;
  final String nickname;
  final String timezone;
  final String nextRoute;
  final String? previewMessage;

  @override
  State<FigmaWireframeExperience> createState() =>
      _FigmaWireframeExperienceState();
}

class _FigmaWireframeExperienceState extends State<FigmaWireframeExperience> {
  bool _hasCompletedOnboarding = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasCompletedOnboarding) {
      return _OnboardingFlow(
        previewMessage: widget.previewMessage,
        onComplete: () {
          setState(() {
            _hasCompletedOnboarding = true;
          });
        },
      );
    }

    return _MindRouterShell(
      nickname: widget.nickname,
      timezone: widget.timezone,
      nextRoute: widget.nextRoute,
      userId: widget.userId,
      previewMessage: widget.previewMessage,
    );
  }
}

class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow({required this.onComplete, this.previewMessage});

  final VoidCallback onComplete;
  final String? previewMessage;

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final _OnboardingStepData data = _steps[_step];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      body: Stack(
        children: <Widget>[
          const SpaceBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: <Widget>[
                        if (widget.previewMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _PreviewModeBanner(
                              message: widget.previewMessage!,
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(
                            _steps.length,
                            (int index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: index == _step ? 32 : 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: index <= _step
                                    ? const Color(0xFF818CF8)
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Column(
                            key: ValueKey<int>(_step),
                            children: <Widget>[
                              SizedBox(
                                height: 240,
                                child: Center(
                                  child: data.visualBuilder(context),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                data.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                data.description,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                      height: 1.6,
                                    ),
                              ),
                              if (data.note != null) ...<Widget>[
                                const SizedBox(height: 22),
                                _OnboardingNote(text: data.note!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _handlePrimaryAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              _step == _steps.length - 1
                                  ? '알림 허용하고 시작하기'
                                  : _step == 0
                                  ? '시작하기'
                                  : '계속하기',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_step == _steps.length - 1)
                          TextButton(
                            onPressed: widget.onComplete,
                            child: Text(
                              '나중에 하기',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 48),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handlePrimaryAction() {
    if (_step < _steps.length - 1) {
      setState(() {
        _step += 1;
      });
      return;
    }

    widget.onComplete();
  }
}

class _OnboardingNote extends StatelessWidget {
  const _OnboardingNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16172B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MindRouterShell extends StatefulWidget {
  const _MindRouterShell({
    required this.nickname,
    required this.timezone,
    required this.nextRoute,
    required this.userId,
    this.previewMessage,
  });

  final String nickname;
  final String timezone;
  final String nextRoute;
  final String userId;
  final String? previewMessage;

  @override
  State<_MindRouterShell> createState() => _MindRouterShellState();
}

class _MindRouterShellState extends State<_MindRouterShell> {
  int _currentIndex = 0;
  _ProfileSubPage _profileSubPage = _ProfileSubPage.profile;

  @override
  Widget build(BuildContext context) {
    final Widget profilePage = switch (_profileSubPage) {
      _ProfileSubPage.settings => SettingsPage(onBack: _closeProfileSubPage),
      _ProfileSubPage.todayMission => TodayMissionPage(
        onBack: _closeProfileSubPage,
      ),
      _ProfileSubPage.profile => ProfilePage(
        nickname: widget.nickname,
        timezone: widget.timezone,
        nextRoute: widget.nextRoute,
        userId: widget.userId,
        onOpenSettings: _openSettings,
        onOpenMission: _openTodayMission,
      ),
    };

    final List<Widget> pages = <Widget>[
      EmotionHomePage(
        nickname: widget.nickname,
        timezone: widget.timezone,
        isPreviewMode: widget.previewMessage != null,
      ),
      ConstellationPage(
        userId: widget.userId,
        isPreviewMode: widget.previewMessage != null,
      ),
      const ComfortPage(),
      profilePage,
    ];

    return PopScope(
      canPop: _profileSubPage == _ProfileSubPage.profile,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _profileSubPage != _ProfileSubPage.profile) {
          _closeProfileSubPage();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0C15),
        body: Stack(
          children: <Widget>[
            const SpaceBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  if (widget.previewMessage != null)
                    _PreviewModeBanner(message: widget.previewMessage!),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: pages),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xCC121320),
            indicatorColor: const Color(0x336366F1),
            labelTextStyle: WidgetStatePropertyAll<TextStyle>(
              TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
              (Set<WidgetState> states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFFC7D2FE)
                    : Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: NavigationBar(
            height: 72,
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
                if (index != 3) {
                  _profileSubPage = _ProfileSubPage.profile;
                }
              });
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: '오늘',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_mosaic_outlined),
                selectedIcon: Icon(Icons.auto_awesome_mosaic),
                label: '별자리',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: '위로',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '나',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    setState(() {
      _profileSubPage = _ProfileSubPage.settings;
    });
  }

  void _openTodayMission() {
    setState(() {
      _profileSubPage = _ProfileSubPage.todayMission;
    });
  }

  void _closeProfileSubPage() {
    setState(() {
      _profileSubPage = _ProfileSubPage.profile;
    });
  }
}

enum _ProfileSubPage { profile, settings, todayMission }

class _PreviewModeBanner extends StatelessWidget {
  const _PreviewModeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x1A38BDF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x6638BDF8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.visibility_outlined,
                color: Color(0xFF7DD3FC),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Preview Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.title,
    required this.description,
    required this.visualBuilder,
    this.note,
  });

  final String title;
  final String description;
  final WidgetBuilder visualBuilder;
  final String? note;
}

const List<_OnboardingStepData> _steps = <_OnboardingStepData>[
  _OnboardingStepData(
    title: '안전한 우주 공간',
    description: '복잡한 생각은 내려놓고, 당신만의 감정 구슬을 띄워보세요.\nMind Router가 다정하게 받아줄게요.',
    visualBuilder: _buildIntroVisual,
  ),
  _OnboardingStepData(
    title: '기록의 시작점',
    description: '현재 개발 단계에서는 실제 회원가입 대신,\n감정 기록 흐름을 먼저 안전하게 연결하고 있어요.',
    visualBuilder: _buildLockVisual,
    note: 'Supabase 익명 로그인으로 진입한 뒤, 이후 단계에서 프로필과 감정 기록을 정식 연결합니다.',
  ),
  _OnboardingStepData(
    title: '다정한 위로 받기',
    description:
        '맞춤 미션과 심리 스니펫은 다음 구현 단계에서 이어집니다.\n지금은 화면 경험과 동선을 먼저 다듬는 중이에요.',
    visualBuilder: _buildBellVisual,
    note: '이 화면은 Figma 와이어프레임을 Flutter에 포팅한 초안입니다. 아직 일부 기능은 플레이스홀더 상태예요.',
  ),
];

Widget _buildIntroVisual(BuildContext context) {
  return Stack(
    alignment: Alignment.center,
    children: const <Widget>[
      _VisualOrb(
        size: 112,
        color: Color(0xFF818CF8),
        alignment: Alignment(-0.4, -0.3),
      ),
      _VisualOrb(
        size: 132,
        color: Color(0xFFA78BFA),
        alignment: Alignment(0.38, 0.22),
      ),
      _VisualOrb(
        size: 74,
        color: Color(0xFF34D399),
        alignment: Alignment(0.66, -0.42),
      ),
    ],
  );
}

Widget _buildLockVisual(BuildContext context) {
  return Center(
    child: Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        color: const Color(0x336366F1),
        border: Border.all(color: const Color(0x556366F1)),
      ),
      child: const Icon(Icons.lock_outline, color: Color(0xFFA5B4FC), size: 54),
    ),
  );
}

Widget _buildBellVisual(BuildContext context) {
  return Stack(
    alignment: Alignment.center,
    children: <Widget>[
      Container(
        width: 168,
        height: 168,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x226366F1),
          border: Border.all(color: const Color(0x446366F1)),
        ),
      ),
      Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: Color(0xFFA5B4FC),
          size: 54,
        ),
      ),
      Positioned(
        top: 38,
        right: 36,
        child: Icon(
          Icons.auto_awesome,
          color: const Color(0xFFFDE68A).withValues(alpha: 0.92),
        ),
      ),
    ],
  );
}

class _VisualOrb extends StatelessWidget {
  const _VisualOrb({
    required this.size,
    required this.color,
    required this.alignment,
  });

  final double size;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0.05)],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 34,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
