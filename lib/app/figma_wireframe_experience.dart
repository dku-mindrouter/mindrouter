import 'package:flutter/material.dart';

class FigmaWireframeExperience extends StatefulWidget {
  const FigmaWireframeExperience({
    super.key,
    required this.userId,
    required this.nickname,
    required this.timezone,
    required this.nextRoute,
  });

  final String userId;
  final String nickname;
  final String timezone;
  final String nextRoute;

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
    );
  }
}

class _OnboardingFlow extends StatefulWidget {
  const _OnboardingFlow({required this.onComplete});

  final VoidCallback onComplete;

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
          const _SpaceBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: <Widget>[
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
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Column(
                      key: ValueKey<int>(_step),
                      children: <Widget>[
                        SizedBox(
                          height: 240,
                          child: Center(child: data.visualBuilder(context)),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
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
                                color: Colors.white.withValues(alpha: 0.68),
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
                  const Spacer(),
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
  });

  final String nickname;
  final String timezone;
  final String nextRoute;
  final String userId;

  @override
  State<_MindRouterShell> createState() => _MindRouterShellState();
}

class _MindRouterShellState extends State<_MindRouterShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _HomePage(nickname: widget.nickname),
      const _ConstellationPage(),
      const _ComfortPage(),
      _ProfilePage(
        nickname: widget.nickname,
        timezone: widget.timezone,
        nextRoute: widget.nextRoute,
        userId: widget.userId,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C15),
      body: Stack(
        children: <Widget>[
          const _SpaceBackdrop(),
          SafeArea(
            bottom: false,
            child: IndexedStack(index: _currentIndex, children: pages),
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
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({required this.nickname});

  final String nickname;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final Set<String> _selectedEmotionIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final _InsightData? insight = _resolveInsight();
    final List<_EmotionBubbleData> selected = _emotionOptions
        .where(
          (_EmotionBubbleData emotion) =>
              _selectedEmotionIds.contains(emotion.id),
        )
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '오늘 밤의 마음',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.nickname}님과 가까운 감정을 1~3개 골라보세요.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.64),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            height: 420,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Stack(
              children: <Widget>[
                ..._emotionOptions.map(
                  (_EmotionBubbleData emotion) => _EmotionBubble(
                    data: emotion,
                    selected: _selectedEmotionIds.contains(emotion.id),
                    faded:
                        _selectedEmotionIds.isNotEmpty &&
                        !_selectedEmotionIds.contains(emotion.id),
                    onTap: () => _toggleEmotion(emotion),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: selected
                .map(
                  (_EmotionBubbleData emotion) => Chip(
                    label: Text(emotion.name),
                    backgroundColor: emotion.color.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: emotion.color.withValues(alpha: 0.4),
                    ),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIconColor: Colors.white70,
                    onDeleted: () => _toggleEmotion(emotion),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 24),
          if (insight != null)
            _InsightCard(
              title: insight.title,
              description: insight.description,
              badge: insight.badge,
              accentColor: insight.accentColor,
            )
          else
            const _PromptCard(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedEmotionIds.isEmpty
                  ? null
                  : _showPostingPlaceholder,
              style: FilledButton.styleFrom(
                backgroundColor:
                    insight?.accentColor ?? const Color(0xFF5B64F6),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                _selectedEmotionIds.isEmpty
                    ? '감정을 먼저 선택해 주세요'
                    : '별 띄우기 (${_selectedEmotionIds.length}/3)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEmotion(_EmotionBubbleData emotion) {
    setState(() {
      if (_selectedEmotionIds.contains(emotion.id)) {
        _selectedEmotionIds.remove(emotion.id);
        return;
      }

      if (_selectedEmotionIds.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 3개의 감정까지만 선택할 수 있어요.')),
        );
        return;
      }

      _selectedEmotionIds.add(emotion.id);
    });
  }

  void _showPostingPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('별 띄우기와 미션 연결은 다음 단계에서 실제 데이터와 붙일 예정입니다.')),
    );
  }

  _InsightData? _resolveInsight() {
    if (_selectedEmotionIds.isEmpty) {
      return null;
    }

    if (_selectedEmotionIds.contains('depression') &&
        _selectedEmotionIds.contains('insomnia')) {
      return const _InsightData(
        title: '수면 사이클이 흔들리고 계신가요?',
        description: '우울감과 불면이 겹칠 때는 무리하게 잠을 청하기보다, 호흡을 천천히 가라앉히는 루틴이 먼저 필요해요.',
        badge: '수면 사이클 안정화',
        accentColor: Color(0xFF4753A6),
      );
    }

    if (_selectedEmotionIds.contains('depression') &&
        _selectedEmotionIds.contains('exhaustion')) {
      return const _InsightData(
        title: '에너지가 많이 소진된 하루였네요',
        description: '우울함과 지침이 함께 오면 해결보다 회복이 우선일 수 있어요. 오늘은 쉬는 계획을 세워도 괜찮습니다.',
        badge: '완전한 휴식 필요',
        accentColor: Color(0xFFB28A43),
      );
    }

    if (_selectedEmotionIds.contains('depression')) {
      return const _InsightData(
        title: '마음이 무겁게 가라앉는 밤입니다',
        description:
            '우울함은 나약함이 아니라 지나가는 상태예요. 지금의 감정을 이름 붙이는 것만으로도 충분히 잘하고 있어요.',
        badge: '조용한 위로',
        accentColor: Color(0xFF4C5FAF),
      );
    }

    final _EmotionBubbleData primary = _emotionOptions.firstWhere(
      (_EmotionBubbleData emotion) => _selectedEmotionIds.contains(emotion.id),
    );

    return _InsightData(
      title: '${primary.name}이 지금의 중심 감정으로 보여요',
      description: '복합적인 감정이 함께 있어도 괜찮아요. 이 감정들을 기록하면 다음 단계의 위로와 미션 설계가 쉬워집니다.',
      badge: '복합 감정 인지',
      accentColor: primary.color,
    );
  }
}

class _EmotionBubble extends StatelessWidget {
  const _EmotionBubble({
    required this.data,
    required this.selected,
    required this.faded,
    required this.onTap,
  });

  final _EmotionBubbleData data;
  final bool selected;
  final bool faded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double size = selected ? 106 : 94;

    return Align(
      alignment: data.alignment,
      child: AnimatedScale(
        scale: selected
            ? 1.08
            : faded
            ? 0.88
            : 1,
        duration: const Duration(milliseconds: 220),
        child: AnimatedOpacity(
          opacity: faded ? 0.38 : 1,
          duration: const Duration(milliseconds: 220),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    data.color.withValues(alpha: 0.95),
                    data.color.withValues(alpha: 0.12),
                  ],
                ),
                color: data.color.withValues(alpha: 0.24),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: data.color.withValues(alpha: selected ? 0.7 : 0.45),
                    blurRadius: selected ? 30 : 18,
                    spreadRadius: selected ? 2 : 0,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: selected ? 0.32 : 0.12),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        data.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (data.subLabel != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          data.subLabel!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.description,
    required this.badge,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String badge;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF16172B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        '감정 구슬을 선택하면 오늘의 심리 스니펫과 다음 액션 영역을 여기에 연결할 수 있어요.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.72),
          height: 1.6,
        ),
      ),
    );
  }
}

class _ConstellationPage extends StatefulWidget {
  const _ConstellationPage();

  @override
  State<_ConstellationPage> createState() => _ConstellationPageState();
}

class _ConstellationPageState extends State<_ConstellationPage> {
  String _selectedFilter = '전체';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '오늘 밤의 은하수',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF818CF8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '1,247개의 별이 빛나고 있습니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _constellationFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final String chip = _constellationFilters[index];
                final bool selected = chip == _selectedFilter;
                return ChoiceChip(
                  label: Text(chip),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = chip;
                    });
                  },
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  selectedColor: const Color(0x334F46E5),
                  side: BorderSide(
                    color: selected
                        ? const Color(0x554F46E5)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFFC7D2FE)
                        : Colors.white.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(painter: _ConstellationLinePainter()),
                  ),
                  ..._constellationStars.map(
                    (_ConstellationStarData star) => Align(
                      alignment: star.alignment,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${star.label} 상세 화면은 다음 단계에서 연결합니다.',
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (star.isMine)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: const Text(
                                  '나',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Container(
                              width: star.isMine ? 28 : star.size,
                              height: star.isMine ? 28 : star.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: <Color>[
                                    star.color,
                                    star.color.withValues(alpha: 0.05),
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: star.color.withValues(
                                      alpha: star.isMine ? 0.78 : 0.5,
                                    ),
                                    blurRadius: star.isMine ? 24 : 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComfortPage extends StatelessWidget {
  const _ComfortPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: <Widget>[
        Text(
          '받은 위로',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '당신의 밤을 밝힌 따뜻한 마음들',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.64),
          ),
        ),
        const SizedBox(height: 24),
        ..._comfortItems.map(
          (_ComfortItemData item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.color.withValues(alpha: 0.14),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              item.time,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.42),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description,
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
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.nickname,
    required this.timezone,
    required this.nextRoute,
    required this.userId,
  });

  final String nickname;
  final String timezone;
  final String nextRoute;
  final String userId;

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
        Text(
          '내 별',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '오늘 밤 11:28 등록됨',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xCC1C1E34),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
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
                    Row(
                      children: const <Widget>[
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xCC1C1E34), Color(0xCC2A2D4A)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x336366F1)),
          ),
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
                child: const Icon(Icons.wb_sunny_outlined, color: Colors.white),
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
        const SizedBox(height: 16),
        Row(
          children: const <Widget>[
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x801C1E34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x801C1E34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x801C1E34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
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

class _SpaceBackdrop extends StatelessWidget {
  const _SpaceBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0A0B14),
                  Color(0xFF0F1123),
                  Color(0xFF111427),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -60,
          child: _GlowOrb(size: 240, color: const Color(0x803B82F6)),
        ),
        Positioned(
          bottom: 40,
          right: -50,
          child: _GlowOrb(size: 220, color: const Color(0x665B21B6)),
        ),
        Positioned(
          top: 200,
          right: 40,
          child: _GlowOrb(size: 140, color: const Color(0x664DD0E1)),
        ),
        ..._starPositions.map(
          (Alignment alignment) => Align(
            alignment: alignment,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color, blurRadius: size / 2, spreadRadius: 8),
        ],
      ),
    );
  }
}

class _ConstellationLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.34)
      ..lineTo(size.width * 0.46, size.height * 0.2)
      ..lineTo(size.width * 0.62, size.height * 0.46)
      ..lineTo(size.width * 0.34, size.height * 0.62);

    final Path secondary = Path()
      ..moveTo(size.width * 0.18, size.height * 0.7)
      ..lineTo(size.width * 0.34, size.height * 0.62);

    canvas.drawPath(path, paint);
    canvas.drawPath(secondary, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _EmotionBubbleData {
  const _EmotionBubbleData({
    required this.id,
    required this.name,
    required this.color,
    required this.alignment,
    this.subLabel,
  });

  final String id;
  final String name;
  final Color color;
  final Alignment alignment;
  final String? subLabel;
}

class _InsightData {
  const _InsightData({
    required this.title,
    required this.description,
    required this.badge,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String badge;
  final Color accentColor;
}

class _ConstellationStarData {
  const _ConstellationStarData({
    required this.label,
    required this.alignment,
    required this.color,
    required this.size,
    this.isMine = false,
  });

  final String label;
  final Alignment alignment;
  final Color color;
  final double size;
  final bool isMine;
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

class _ComfortItemData {
  const _ComfortItemData({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
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

const List<_EmotionBubbleData> _emotionOptions = <_EmotionBubbleData>[
  _EmotionBubbleData(
    id: 'depression',
    name: '#우울함',
    color: Color(0xFF6E7BF5),
    alignment: Alignment(-0.68, -0.88),
    subLabel: 'down',
  ),
  _EmotionBubbleData(
    id: 'insomnia',
    name: '#불면',
    color: Color(0xFF54C1FF),
    alignment: Alignment(0.64, -0.64),
    subLabel: 'awake',
  ),
  _EmotionBubbleData(
    id: 'exhaustion',
    name: '#지침',
    color: Color(0xFFF4B86A),
    alignment: Alignment(-0.48, -0.22),
    subLabel: 'drained',
  ),
  _EmotionBubbleData(
    id: 'anxiety',
    name: '#불안',
    color: Color(0xFFE879F9),
    alignment: Alignment(0.72, -0.06),
    subLabel: 'uneasy',
  ),
  _EmotionBubbleData(
    id: 'lonely',
    name: '#외로움',
    color: Color(0xFF8B7CF8),
    alignment: Alignment(-0.76, 0.3),
    subLabel: 'alone',
  ),
  _EmotionBubbleData(
    id: 'relief',
    name: '#안도',
    color: Color(0xFF4ADE80),
    alignment: Alignment(0.46, 0.26),
    subLabel: 'rest',
  ),
  _EmotionBubbleData(
    id: 'hope',
    name: '#희망',
    color: Color(0xFFFB7185),
    alignment: Alignment(-0.3, 0.76),
    subLabel: 'hope',
  ),
  _EmotionBubbleData(
    id: 'gratitude',
    name: '#감사',
    color: Color(0xFFFACC15),
    alignment: Alignment(0.62, 0.82),
    subLabel: 'warm',
  ),
];

const List<Alignment> _starPositions = <Alignment>[
  Alignment(-0.82, -0.96),
  Alignment(-0.32, -0.74),
  Alignment(0.58, -0.72),
  Alignment(0.84, -0.24),
  Alignment(-0.74, -0.08),
  Alignment(0.2, 0.12),
  Alignment(-0.48, 0.48),
  Alignment(0.76, 0.54),
  Alignment(-0.1, 0.84),
];

const List<String> _constellationFilters = <String>[
  '전체',
  '비슷한 감정',
  '밤 시간대',
  '내 주변',
];

const List<_ConstellationStarData> _constellationStars =
    <_ConstellationStarData>[
      _ConstellationStarData(
        label: '내 별',
        alignment: Alignment(-0.25, -0.1),
        color: Color(0xFF7C3AED),
        size: 22,
        isMine: true,
      ),
      _ConstellationStarData(
        label: '비슷한 감정',
        alignment: Alignment(0.18, -0.38),
        color: Color(0xFF60A5FA),
        size: 18,
      ),
      _ConstellationStarData(
        label: '근처 사용자',
        alignment: Alignment(0.52, 0.1),
        color: Color(0xFFF472B6),
        size: 16,
      ),
      _ConstellationStarData(
        label: '밤 시간대',
        alignment: Alignment(-0.6, 0.28),
        color: Color(0xFFFBBF24),
        size: 14,
      ),
      _ConstellationStarData(
        label: '유사 패턴',
        alignment: Alignment(0.7, -0.7),
        color: Color(0xFF34D399),
        size: 12,
      ),
      _ConstellationStarData(
        label: '공감 연결',
        alignment: Alignment(-0.72, -0.54),
        color: Color(0xFFA78BFA),
        size: 14,
      ),
      _ConstellationStarData(
        label: '근처 감정',
        alignment: Alignment(0.42, 0.7),
        color: Color(0xFFFB7185),
        size: 15,
      ),
    ];

const List<_ComfortItemData> _comfortItems = <_ComfortItemData>[
  _ComfortItemData(
    title: '따뜻한 차',
    description: '누군가 당신의 별에 따뜻한 차를 전했습니다.',
    time: '10분 전',
    icon: Icons.coffee_outlined,
    color: Color(0xFFFBBF24),
  ),
  _ComfortItemData(
    title: '안아드려요',
    description: '익명의 이웃이 당신을 따뜻하게 안아주었습니다.',
    time: '2시간 전',
    icon: Icons.favorite_border,
    color: Color(0xFFFB7185),
  ),
  _ComfortItemData(
    title: '오늘의 심리 스니펫',
    description: '자고 일어났는데 무기력하다면, 오늘 점심엔 5분만 햇볕을 쬐어보세요. 세로토닌이 올라옵니다.',
    time: '어제',
    icon: Icons.auto_awesome_outlined,
    color: Color(0xFF818CF8),
  ),
  _ComfortItemData(
    title: '가벼운 산책',
    description: '오늘 날씨가 맑아요. 좋아하는 음악 틀고 딱 10분만 걸어볼까요?',
    time: '어제',
    icon: Icons.wb_cloudy_outlined,
    color: Color(0xFF38BDF8),
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
