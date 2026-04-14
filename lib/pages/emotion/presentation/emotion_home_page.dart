import 'dart:ui';

import 'package:flutter/material.dart';

class EmotionHomePage extends StatefulWidget {
  const EmotionHomePage({super.key, required this.nickname});

  final String nickname;

  @override
  State<EmotionHomePage> createState() => _EmotionHomePageState();
}

class _EmotionHomePageState extends State<EmotionHomePage> {
  final Set<String> _selectedEmotionIds = <String>{};
  bool _isInsightSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final _InsightData? insight = _resolveInsight();

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 160),
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
                '가까운 감정 구슬을 1~3개 터치하세요',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2026.04.13',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF51557A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Center(
                  child: SizedBox(
                    width: 345,
                    height: 500,
                    child: Stack(
                      children: <Widget>[
                        ..._homeStarDots,
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
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Text(
                            '여러 감정이 겹친다면 함께 선택해주세요',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF656A8D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
        if (insight != null && _isInsightSheetOpen) ...<Widget>[
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeInsightSheet,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withValues(alpha: 0.28)),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _InsightBottomSheet(
              insight: insight,
              selectionCount: _selectedEmotionIds.length,
              onClose: _closeInsightSheet,
              onAddEmotion: _closeInsightSheet,
              onPrimaryAction: _showPostingPlaceholder,
            ),
          ),
        ],
      ],
    );
  }

  void _toggleEmotion(_EmotionBubbleData emotion) {
    setState(() {
      if (_selectedEmotionIds.contains(emotion.id)) {
        _selectedEmotionIds.remove(emotion.id);
        if (_selectedEmotionIds.isEmpty) {
          _isInsightSheetOpen = false;
        }
        return;
      }

      if (_selectedEmotionIds.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 3개의 감정까지만 선택할 수 있어요.')),
        );
        return;
      }

      _selectedEmotionIds.add(emotion.id);
      _isInsightSheetOpen = true;
    });
  }

  void _closeInsightSheet() {
    setState(() {
      _isInsightSheetOpen = false;
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

    return Positioned(
      left: data.left,
      top: data.top,
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

class _InsightBottomSheet extends StatelessWidget {
  const _InsightBottomSheet({
    required this.insight,
    required this.selectionCount,
    required this.onClose,
    required this.onAddEmotion,
    required this.onPrimaryAction,
  });

  final _InsightData insight;
  final int selectionCount;
  final VoidCallback onClose;
  final VoidCallback onAddEmotion;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF191B34),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
            bottom: Radius.circular(28),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 38,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.auto_awesome,
                        color: insight.accentColor.withValues(alpha: 0.95),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '심리 스니펫 · COGNITIVE INSIGHT',
                        style: TextStyle(
                          color: insight.accentColor.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '"${insight.title}"',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    insight.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const <Widget>[
                      _InsightTag(
                        label: '마음 챙김',
                        color: Color(0xFFB1794E),
                        dotColor: Color(0xFFE0A35E),
                      ),
                      _InsightTag(
                        label: '7일 연속 기록',
                        color: Color(0xFF5857C3),
                        dotColor: Color(0xFF8B84FF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Flexible(
                    flex: 8,
                    child: _SheetSecondaryButton(
                      onPressed: onAddEmotion,
                      label: '감정 추가 ($selectionCount/3)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 12,
                    child: _SheetPrimaryButton(
                      onPressed: onPrimaryAction,
                      label: '은하수에 별 띄우기',
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

class _SheetSecondaryButton extends StatelessWidget {
  const _SheetSecondaryButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.92),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          backgroundColor: const Color(0xFF232648),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Color(0xFFC18C6F),
              Color(0xFFB08EB7),
              Color(0xFF8F6ED8),
            ],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x40A076D0),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightTag extends StatelessWidget {
  const _InsightTag({
    required this.label,
    required this.color,
    required this.dotColor,
  });

  final String label;
  final Color color;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionBubbleData {
  const _EmotionBubbleData({
    required this.id,
    required this.name,
    required this.color,
    required this.left,
    required this.top,
    this.subLabel,
  });

  final String id;
  final String name;
  final Color color;
  final double left;
  final double top;
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

class _TinyStar extends StatelessWidget {
  const _TinyStar({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

const List<_EmotionBubbleData> _emotionOptions = <_EmotionBubbleData>[
  _EmotionBubbleData(
    id: 'lethargy',
    name: '#무기력',
    color: Color(0xFFB68355),
    left: 36,
    top: 28,
    subLabel: '텅 빈 느낌',
  ),
  _EmotionBubbleData(
    id: 'calm',
    name: '#잔잔함',
    color: Color(0xFF6FB1A9),
    left: 188,
    top: 84,
    subLabel: '평온',
  ),
  _EmotionBubbleData(
    id: 'emptiness',
    name: '#공허함',
    color: Color(0xFF6F55B5),
    left: 53,
    top: 139,
    subLabel: '이유 없이',
  ),
  _EmotionBubbleData(
    id: 'depression',
    name: '#우울함',
    color: Color(0xFF5D72C6),
    left: 205,
    top: 176,
    subLabel: '가라앉음',
  ),
  _EmotionBubbleData(
    id: 'exhaustion',
    name: '#지침',
    color: Color(0xFFC1A34A),
    left: 36,
    top: 231,
    subLabel: '다 쏟아냈어',
  ),
  _EmotionBubbleData(
    id: 'insomnia',
    name: '#불면',
    color: Color(0xFF555A8A),
    left: 153,
    top: 268,
    subLabel: '잠이 안 와',
  ),
  _EmotionBubbleData(
    id: 'anxiety',
    name: '#불안',
    color: Color(0xFF6842A8),
    left: 70,
    top: 323,
    subLabel: '조마조마',
  ),
  _EmotionBubbleData(
    id: 'irritation',
    name: '#짜증',
    color: Color(0xFFAF5A71),
    left: 188,
    top: 341,
    subLabel: '건들지마',
  ),
];

const List<Positioned> _homeStarDots = <Positioned>[
  Positioned(left: 290, top: 76, child: _TinyStar(size: 6, opacity: 0.45)),
  Positioned(left: 334, top: 83, child: _TinyStar(size: 4, opacity: 0.55)),
  Positioned(left: 20, top: 330, child: _TinyStar(size: 2, opacity: 0.5)),
  Positioned(left: 292, top: 447, child: _TinyStar(size: 4, opacity: 0.45)),
];
