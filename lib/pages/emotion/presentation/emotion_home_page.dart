import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/emotion_repository.dart';
import '../data/supabase_emotion_data_source.dart';
import '../domain/emotion_composer_policy.dart';
import '../domain/emotion_exception.dart';
import '../domain/emotion_tag.dart';
import '../domain/emotion_validation_policy.dart';
import '../domain/time_bucket_policy.dart';
import '../domain/today_star_status.dart';

class EmotionHomePage extends StatefulWidget {
  const EmotionHomePage({
    super.key,
    required this.nickname,
    required this.timezone,
    required this.isPreviewMode,
  });

  final String nickname;
  final String timezone;
  final bool isPreviewMode;

  @override
  State<EmotionHomePage> createState() => _EmotionHomePageState();
}

class _EmotionHomePageState extends State<EmotionHomePage> {
  final Set<String> _selectedEmotionIds = <String>{};
  final TextEditingController _contentController = TextEditingController();

  bool _isInsightSheetOpen = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadErrorMessage;
  List<EmotionTag> _emotionTags = const <EmotionTag>[];
  TodayStarStatus? _todayStatus;

  EmotionRepository get _emotionRepository => EmotionRepository(
    dataSource: SupabaseEmotionDataSource(client: Supabase.instance.client),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.isPreviewMode) {
      _loadEmotionData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _InsightData? insight = _resolveInsight();
    final Map<String, EmotionTag> tagsByOptionId = _resolveTagsByOptionId();
    final bool isComposerLocked = _isComposerLocked;
    final List<String> missingTagLabels = _missingTagLabels(tagsByOptionId);

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
                '가까운 감정 구슬을 1~3개 선택해보세요.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF51557A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const _EmotionStatusCard(
                  icon: Icons.sync,
                  message: '감정 태그와 오늘 상태를 불러오는 중입니다.',
                )
              else if (_loadErrorMessage != null)
                _EmotionStatusCard(
                  icon: Icons.error_outline,
                  message: _loadErrorMessage!,
                  actionLabel: '다시 시도',
                  onAction: _loadEmotionData,
                )
              else if (_todayStatus?.hasCreatedToday == true)
                const _EmotionStatusCard(
                  icon: Icons.check_circle_outline,
                  message: '오늘은 이미 별을 띄웠습니다. 내일 다시 기록할 수 있어요.',
                )
              else if (missingTagLabels.isNotEmpty)
                _EmotionStatusCard(
                  icon: Icons.info_outline,
                  message:
                      '서버 감정 태그와 연결되지 않은 구슬은 잠시 비활성화했어요: ${missingTagLabels.join(', ')}',
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
                            enabled:
                                !isComposerLocked &&
                                _isEmotionAvailable(
                                  emotion: emotion,
                                  tagsByOptionId: tagsByOptionId,
                                ),
                            faded:
                                _selectedEmotionIds.isNotEmpty &&
                                !_selectedEmotionIds.contains(emotion.id),
                            onTap: () => _toggleEmotion(
                              emotion,
                              tagsByOptionId: tagsByOptionId,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Text(
                            '여러 감정이 겹친다면 함께 선택해도 괜찮아요',
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
              onPrimaryAction: _submitEmotion,
              contentController: _contentController,
              onContentChanged: (_) => setState(() {}),
              maxContentLength: 80,
              primaryLabel: _isSubmitting ? '별을 띄우는 중...' : '은하수에 별 띄우기',
              isPrimaryEnabled:
                  !isComposerLocked &&
                  !_isSubmitting &&
                  _selectedEmotionIds.isNotEmpty &&
                  _contentController.text.trim().isNotEmpty &&
                  _selectedEmotionIds.every(tagsByOptionId.containsKey),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _loadEmotionData() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final List<EmotionTag> emotionTags = await _emotionRepository
          .fetchEmotionTags();
      final TodayStarStatus todayStatus = await _emotionRepository
          .fetchTodayStarStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _emotionTags = emotionTags;
        _todayStatus = todayStatus;
        _isLoading = false;
        _loadErrorMessage = emotionTags.isEmpty
            ? '사용 가능한 감정 태그를 찾지 못했습니다. seed 데이터를 확인해 주세요.'
            : null;
        if (todayStatus.hasCreatedToday || emotionTags.isEmpty) {
          _selectedEmotionIds.clear();
          _contentController.clear();
          _isInsightSheetOpen = false;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final EmotionException exception = _emotionRepository
          .mapToEmotionException(error);
      setState(() {
        _isLoading = false;
        _loadErrorMessage = _mapEmotionErrorToMessage(exception);
        _selectedEmotionIds.clear();
        _isInsightSheetOpen = false;
      });
    }
  }

  void _toggleEmotion(
    _EmotionBubbleData emotion, {
    required Map<String, EmotionTag> tagsByOptionId,
  }) {
    if (_isComposerLocked) {
      _showSnackBar(_composerLockedMessage);
      return;
    }

    if (!_isEmotionAvailable(
      emotion: emotion,
      tagsByOptionId: tagsByOptionId,
    )) {
      _showSnackBar('${emotion.name}은 아직 서버 감정 태그와 연결되지 않았습니다.');
      return;
    }

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

  Future<void> _submitEmotion() async {
    if (_isSubmitting) {
      return;
    }

    if (widget.isPreviewMode) {
      _showSnackBar('Preview Mode에서는 실제 별 저장이 동작하지 않습니다.');
      return;
    }

    if (_isLoading) {
      _showSnackBar('아직 감정 태그를 불러오는 중입니다.');
      return;
    }

    if (_todayStatus?.hasCreatedToday == true) {
      _showSnackBar('오늘은 이미 별을 띄웠습니다.');
      return;
    }

    final String content = _contentController.text.trim();
    if (content.isEmpty) {
      _showSnackBar('별과 함께 남길 글을 입력해 주세요.');
      return;
    }

    final Map<String, EmotionTag> tagsByOptionId = _resolveTagsByOptionId();
    final List<EmotionTag> selectedTags = _resolveSelectedEmotionTags(
      tagsByOptionId: tagsByOptionId,
    );
    if (selectedTags.length != _selectedEmotionIds.length) {
      _showSnackBar('선택한 감정을 아직 서버 태그와 완전히 연결하지 못했습니다.');
      return;
    }

    final List<int> tagIds = selectedTags
        .map((EmotionTag tag) => tag.id)
        .toList(growable: false);

    final bool canSubmit = checkCanSubmitEmotion(
      tagIds: tagIds,
      isSubmitting: _isSubmitting,
    );
    if (!canSubmit) {
      _showSnackBar('감정을 1개 이상 선택한 뒤 다시 시도해 주세요.');
      return;
    }

    try {
      await checkEmotionTagLimit(tagIds: tagIds, maxCount: 3);
      await checkEmotionContentPolicy(content: content, maxLength: 80);

      setState(() {
        _isSubmitting = true;
      });

      await _emotionRepository.createStar(
        content: content,
        tagIds: tagIds,
        timeBucket: getTimeBucketByLocalTime(
          now: DateTime.now(),
          timezone: widget.timezone,
        ),
        visibilityStatus: 'public',
        emotionIntensity: math.min(tagIds.length, 5),
      );

      final TodayStarStatus refreshedStatus = await _emotionRepository
          .fetchTodayStarStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _selectedEmotionIds.clear();
        _contentController.clear();
        _isInsightSheetOpen = false;
        _todayStatus = refreshedStatus;
      });

      _showSnackBar('오늘의 감정을 은하수에 기록했습니다.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      final EmotionException exception = _emotionRepository
          .mapToEmotionException(error);
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar(_mapEmotionErrorToMessage(exception));
    }
  }

  Map<String, EmotionTag> _resolveTagsByOptionId() {
    if (widget.isPreviewMode) {
      return <String, EmotionTag>{
        for (final _EmotionBubbleData emotion in _emotionOptions)
          emotion.id: EmotionTag(
            id: _emotionOptions.indexOf(emotion) + 1,
            nameKo: emotion.name.replaceFirst('#', ''),
            groupName: 'preview',
            priority: 0,
            isActive: true,
          ),
      };
    }

    final Map<String, EmotionTag> tagsByName = <String, EmotionTag>{
      for (final EmotionTag tag in _emotionTags)
        _normalizeTagName(tag.nameKo): tag,
    };

    final Map<String, EmotionTag> tagsByOptionId = <String, EmotionTag>{};
    for (final _EmotionBubbleData emotion in _emotionOptions) {
      final EmotionTag? matchedTag = _resolveTagForEmotion(
        emotion: emotion,
        tagsByName: tagsByName,
      );
      if (matchedTag != null) {
        tagsByOptionId[emotion.id] = matchedTag;
      }
    }
    return tagsByOptionId;
  }

  List<EmotionTag> _resolveSelectedEmotionTags({
    required Map<String, EmotionTag> tagsByOptionId,
  }) {
    final List<EmotionTag> resolved = <EmotionTag>[];
    for (final _EmotionBubbleData emotion in _emotionOptions) {
      if (!_selectedEmotionIds.contains(emotion.id)) {
        continue;
      }

      final EmotionTag? matchedTag = tagsByOptionId[emotion.id];
      if (matchedTag != null) {
        resolved.add(matchedTag);
      }
    }

    return resolved;
  }

  EmotionTag? _resolveTagForEmotion({
    required _EmotionBubbleData emotion,
    required Map<String, EmotionTag> tagsByName,
  }) {
    final List<String> aliases =
        _emotionTagAliases[emotion.id] ??
        <String>[emotion.name.replaceFirst('#', '')];

    for (final String alias in aliases) {
      final EmotionTag? matchedTag = tagsByName[_normalizeTagName(alias)];
      if (matchedTag != null) {
        return matchedTag;
      }
    }
    return null;
  }

  bool _isEmotionAvailable({
    required _EmotionBubbleData emotion,
    required Map<String, EmotionTag> tagsByOptionId,
  }) {
    return widget.isPreviewMode || tagsByOptionId.containsKey(emotion.id);
  }

  List<String> _missingTagLabels(Map<String, EmotionTag> tagsByOptionId) {
    if (widget.isPreviewMode || _isLoading || _loadErrorMessage != null) {
      return const <String>[];
    }
    return _emotionOptions
        .where(
          (_EmotionBubbleData emotion) =>
              !tagsByOptionId.containsKey(emotion.id),
        )
        .map((_EmotionBubbleData emotion) => emotion.name)
        .toList(growable: false);
  }

  bool get _isComposerLocked {
    return _isLoading ||
        _loadErrorMessage != null ||
        _isSubmitting ||
        _todayStatus?.hasCreatedToday == true;
  }

  String get _composerLockedMessage {
    if (_isLoading) {
      return '감정 태그를 불러온 뒤 선택할 수 있어요.';
    }
    if (_loadErrorMessage != null) {
      return '감정 태그를 다시 불러온 뒤 선택해 주세요.';
    }
    if (_todayStatus?.hasCreatedToday == true) {
      return '오늘은 이미 별을 띄웠습니다.';
    }
    if (_isSubmitting) {
      return '별을 띄우는 중입니다.';
    }
    return '지금은 감정을 선택할 수 없습니다.';
  }

  String _normalizeTagName(String raw) {
    return raw.replaceAll('#', '').replaceAll(' ', '').trim();
  }

  String _mapEmotionErrorToMessage(EmotionException exception) {
    switch (exception.code) {
      case EmotionErrorCode.unauthorized:
        return '익명 로그인 상태를 확인한 뒤 다시 시도해 주세요.';
      case EmotionErrorCode.forbidden:
        return '프로필 또는 권한 상태 때문에 저장할 수 없습니다.';
      case EmotionErrorCode.tagLimitExceeded:
        return '감정은 최대 3개까지 선택할 수 있어요.';
      case EmotionErrorCode.contentTooLong:
        return '글은 80자 이내로 입력해 주세요.';
      case EmotionErrorCode.contentBlockedWord:
        return '입력한 글에 제한된 표현이 포함되어 있습니다.';
      case EmotionErrorCode.dailyStarLimitExceeded:
        return '오늘은 이미 별을 띄웠습니다.';
      case EmotionErrorCode.invalidArgument:
        return '선택한 감정 또는 입력값이 서버 조건과 맞지 않습니다.';
      default:
        return exception.message ?? '별 띄우기 중 문제가 발생했습니다.';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  _InsightData? _resolveInsight() {
    if (_selectedEmotionIds.isEmpty) {
      return null;
    }

    if (_selectedEmotionIds.contains('depression') &&
        _selectedEmotionIds.contains('insomnia')) {
      return const _InsightData(
        title: '외로움과 위로가 함께 필요한 밤이에요',
        description: '마음이 가라앉고 누군가의 온기가 필요할 때는 혼자 버티는 대신 작은 연결을 남겨도 괜찮아요.',
        badge: '위로 연결',
        accentColor: Color(0xFF4753A6),
      );
    }

    if (_selectedEmotionIds.contains('depression') &&
        _selectedEmotionIds.contains('exhaustion')) {
      return const _InsightData(
        title: '에너지가 많이 떨어진 하루였어요',
        description: '우울함과 지침이 함께 오면 해결보다 회복이 우선일 수 있어요. 오늘은 쉬는 계획을 세워도 괜찮습니다.',
        badge: '안전한 휴식 필요',
        accentColor: Color(0xFFB28A43),
      );
    }

    if (_selectedEmotionIds.contains('depression')) {
      return const _InsightData(
        title: '마음이 무겁게 가라앉은 밤입니다',
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

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}

class _EmotionBubble extends StatelessWidget {
  const _EmotionBubble({
    required this.data,
    required this.selected,
    required this.enabled,
    required this.faded,
    required this.onTap,
  });

  final _EmotionBubbleData data;
  final bool selected;
  final bool enabled;
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
          opacity: !enabled
              ? 0.24
              : faded
              ? 0.38
              : 1,
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
                  color: Colors.white.withValues(
                    alpha: !enabled
                        ? 0.06
                        : selected
                        ? 0.32
                        : 0.12,
                  ),
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
    required this.contentController,
    required this.onContentChanged,
    required this.maxContentLength,
    required this.primaryLabel,
    required this.isPrimaryEnabled,
  });

  final _InsightData insight;
  final int selectionCount;
  final VoidCallback onClose;
  final VoidCallback onAddEmotion;
  final VoidCallback onPrimaryAction;
  final TextEditingController contentController;
  final ValueChanged<String> onContentChanged;
  final int maxContentLength;
  final String primaryLabel;
  final bool isPrimaryEnabled;

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.auto_awesome,
                              color: insight.accentColor.withValues(
                                alpha: 0.95,
                              ),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '심리 스니펫 · COGNITIVE INSIGHT',
                              style: TextStyle(
                                color: insight.accentColor.withValues(
                                  alpha: 0.9,
                                ),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          insight.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 15,
                                height: 1.65,
                              ),
                        ),
                        const SizedBox(height: 18),
                        _EmotionContentField(
                          controller: contentController,
                          onChanged: onContentChanged,
                          maxLength: maxContentLength,
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
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
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
                          onPressed: isPrimaryEnabled ? onPrimaryAction : null,
                          label: primaryLabel,
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

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: onPressed == null
                ? const <Color>[Color(0xFF575A76), Color(0xFF4D506A)]
                : const <Color>[
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

class _EmotionStatusCard extends StatelessWidget {
  const _EmotionStatusCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171A2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF8B84FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...<Widget>[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFC7D2FE),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      actionLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionContentField extends StatelessWidget {
  const _EmotionContentField({
    required this.controller,
    required this.onChanged,
    required this.maxLength,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        final int currentLength = value.text.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '별과 함께 남길 글',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 4,
              minLines: 3,
              maxLength: maxLength,
              style: const TextStyle(color: Colors.white, height: 1.45),
              decoration: InputDecoration(
                hintText: '지금 마음을 짧게 적어보세요.',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.34),
                ),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF222540),
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF8B84FF)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$currentLength/$maxLength',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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

const Map<String, List<String>> _emotionTagAliases = <String, List<String>>{
  'lethargy': <String>['무기력'],
  'calm': <String>['잔잔함', '안도'],
  'emptiness': <String>['공허함'],
  'depression': <String>['외로움', '번아웃'],
  'exhaustion': <String>['지침'],
  'insomnia': <String>['위로받고 싶음'],
  'anxiety': <String>['불안'],
  'irritation': <String>['답답함'],
};

const List<_EmotionBubbleData> _emotionOptions = <_EmotionBubbleData>[
  _EmotionBubbleData(
    id: 'lethargy',
    name: '#무기력',
    color: Color(0xFFB68355),
    left: 36,
    top: 28,
    subLabel: '몸이 무거워',
  ),
  _EmotionBubbleData(
    id: 'calm',
    name: '#잔잔함',
    color: Color(0xFF6FB1A9),
    left: 188,
    top: 84,
    subLabel: '안도감',
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
    subLabel: '너무 지쳤어',
  ),
  _EmotionBubbleData(
    id: 'insomnia',
    name: '#위로',
    color: Color(0xFF555A8A),
    left: 153,
    top: 268,
    subLabel: '곁이 필요해',
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
    name: '#답답함',
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
