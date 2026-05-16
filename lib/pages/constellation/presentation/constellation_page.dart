import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/constellation_repository.dart';
import '../data/supabase_constellation_data_source.dart';
import '../domain/constellation_exception.dart';
import '../domain/feed_filter.dart';
import '../domain/star.dart';
import '../domain/today_status.dart';
import '../../emotion/data/emotion_repository.dart';
import '../../emotion/data/supabase_emotion_data_source.dart';
import '../../emotion/domain/emotion_tag.dart';
import '../../reaction/data/reaction_repository.dart';
import '../../reaction/data/supabase_reaction_data_source.dart';
import '../../reaction/domain/reaction_error_message_mapper.dart';
import '../../reaction/domain/reaction_exception.dart';
import '../../reaction/domain/reaction_type.dart';
import '../../reaction/domain/send_reaction_result.dart';

class ConstellationPage extends StatefulWidget {
  const ConstellationPage({
    super.key,
    required this.userId,
    required this.isPreviewMode,
  });

  final String userId;
  final bool isPreviewMode;

  @override
  State<ConstellationPage> createState() => _ConstellationPageState();
}

class _ConstellationPageState extends State<ConstellationPage> {
  FeedFilter _selectedFilter = FeedFilter.all;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadErrorMessage;
  List<Star> _stars = const <Star>[];
  TodayStatus? _todayStatus;

  ConstellationRepository get _repository => ConstellationRepository(
    dataSource: SupabaseConstellationDataSource(
      client: Supabase.instance.client,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPreviewMode) {
      _stars = _previewStars;
      _isLoading = false;
    } else {
      _loadConstellation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        RefreshIndicator(
          color: const Color(0xFFC7D2FE),
          backgroundColor: const Color(0xFF191B34),
          onRefresh: _loadConstellation,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: <Widget>[
              _ConstellationHeader(
                starCount: _stars.length,
                isPreviewMode: widget.isPreviewMode,
              ),
              const SizedBox(height: 14),
              if (_todayStatus != null)
                _TodayStatusStrip(status: _todayStatus!)
              else if (widget.isPreviewMode)
                const _ConstellationStatusStrip(
                  icon: Icons.visibility_outlined,
                  message: 'Preview Mode에서는 샘플 별자리로 화면만 확인합니다.',
                ),
              if (_todayStatus != null || widget.isPreviewMode)
                const SizedBox(height: 16),
              _FilterRail(
                selectedFilter: _selectedFilter,
                isDisabled: _isLoading || _isRefreshing,
                onChanged: _selectFilter,
              ),
              const SizedBox(height: 24),
              SizedBox(height: 500, child: _buildConstellationSurface(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConstellationSurface(BuildContext context) {
    if (_isLoading) {
      return const _ConstellationPanel(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFC7D2FE)),
        ),
      );
    }

    if (_loadErrorMessage != null) {
      return _ConstellationPanel(
        child: _ConstellationMessageState(
          icon: Icons.error_outline,
          title: '은하수를 불러오지 못했습니다',
          message: _loadErrorMessage!,
          actionLabel: '다시 시도',
          onAction: _loadConstellation,
        ),
      );
    }

    if (_stars.isEmpty) {
      return _ConstellationPanel(
        child: _ConstellationMessageState(
          icon: Icons.nights_stay_outlined,
          title: '아직 보이는 별이 없습니다',
          message: _selectedFilter == FeedFilter.all
              ? '다른 사용자의 별이 공개되면 이곳에 은하수가 만들어집니다.'
              : '이 시간대 필터에 맞는 별이 아직 없습니다.',
          actionLabel: '새로고침',
          onAction: _loadConstellation,
        ),
      );
    }

    return _ConstellationPanel(
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: CustomPaint(painter: _ConstellationLinePainter()),
          ),
          ...List<Widget>.generate(_stars.length, (int index) {
            final Star star = _stars[index];
            return Align(
              alignment: _alignmentForIndex(index),
              child: _FeedStarNode(
                star: star,
                color: _colorForStar(star),
                size: _sizeForStar(star),
                isMine: star.userId == widget.userId,
                onTap: () => _openStarDetail(star),
              ),
            );
          }),
          if (_isRefreshing)
            const Positioned(
              right: 18,
              top: 18,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFC7D2FE),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadConstellation() async {
    if (widget.isPreviewMode) {
      setState(() {
        _stars = _previewStars;
        _isLoading = false;
        _loadErrorMessage = null;
      });
      return;
    }

    final bool hadData = _stars.isNotEmpty || _todayStatus != null;
    setState(() {
      _isLoading = !hadData;
      _isRefreshing = hadData;
      _loadErrorMessage = null;
    });

    try {
      final TodayStatus todayStatus = await _repository.fetchTodayStatus();
      final List<Star> stars = await _repository.fetchFeed(
        filterName: feedFilterToName(_selectedFilter),
        limit: 20,
        offset: 0,
      );
      final List<Star> resolvedStars = await _withResolvedTagNames(stars);
      if (!mounted) {
        return;
      }
      setState(() {
        _todayStatus = todayStatus;
        _stars = resolvedStars;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _loadErrorMessage = _mapConstellationErrorToMessage(error);
      });
    }
  }

  void _selectFilter(FeedFilter filter) {
    if (_selectedFilter == filter || _isLoading || _isRefreshing) {
      return;
    }
    setState(() {
      _selectedFilter = filter;
    });
    _loadConstellation();
  }

  Future<void> _openStarDetail(Star star) async {
    final Star? updatedStar = await Navigator.of(context).push<Star>(
      MaterialPageRoute<Star>(
        builder: (BuildContext context) => _StarDetailPage(
          initialStar: star,
          userId: widget.userId,
          isPreviewMode: widget.isPreviewMode,
        ),
      ),
    );
    if (!mounted || updatedStar == null) {
      return;
    }
    setState(() {
      _stars = _stars
          .map((Star feedStar) {
            if (feedStar.starId == updatedStar.starId) {
              return updatedStar;
            }
            return feedStar;
          })
          .toList(growable: false);
    });
  }

  String _mapConstellationErrorToMessage(Object error) {
    final ConstellationException exception = error is ConstellationException
        ? error
        : _repository.mapToConstellationException(error);

    switch (exception.code) {
      case ConstellationErrorCode.unauthorized:
        return '익명 로그인 상태를 확인한 뒤 다시 시도해 주세요.';
      case ConstellationErrorCode.forbidden:
        return '프로필 또는 권한 상태 때문에 은하수를 볼 수 없습니다.';
      case ConstellationErrorCode.starNotFound:
        return '이 별은 더 이상 볼 수 없습니다.';
      case ConstellationErrorCode.blockedRelationship:
        return '차단 관계 때문에 이 별을 볼 수 없습니다.';
      case ConstellationErrorCode.invalidArgument:
        return '요청한 필터나 별 정보가 올바르지 않습니다.';
      default:
        return exception.message ?? '은하수를 불러오는 중 문제가 발생했습니다.';
    }
  }
}

class _ConstellationHeader extends StatelessWidget {
  const _ConstellationHeader({
    required this.starCount,
    required this.isPreviewMode,
  });

  final int starCount;
  final bool isPreviewMode;

  @override
  Widget build(BuildContext context) {
    return Column(
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
              isPreviewMode ? '샘플 별자리가 빛나고 있습니다' : '$starCount개의 별을 불러왔습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayStatusStrip extends StatelessWidget {
  const _TodayStatusStrip({required this.status});

  final TodayStatus status;

  @override
  Widget build(BuildContext context) {
    final String starText = status.hasStarToday
        ? status.isStarExpiredToday
              ? '오늘의 별은 만료되었습니다'
              : '오늘의 별이 은하수에 떠 있습니다'
        : '오늘은 아직 별을 띄우지 않았습니다';
    final String reactionText =
        '위로 ${status.reactionRemainingCount}/${status.reactionDailyLimit}회 남음';

    return _ConstellationStatusStrip(
      icon: status.hasStarToday
          ? Icons.auto_awesome
          : Icons.auto_awesome_outlined,
      message: '$starText · $reactionText',
    );
  }
}

class _ConstellationStatusStrip extends StatelessWidget {
  const _ConstellationStatusStrip({required this.icon, required this.message});

  final IconData icon;
  final String message;

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
        children: <Widget>[
          Icon(icon, color: const Color(0xFF8B84FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.selectedFilter,
    required this.isDisabled,
    required this.onChanged,
  });

  final FeedFilter selectedFilter;
  final bool isDisabled;
  final ValueChanged<FeedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final _FilterOption option = _filterOptions[index];
          final bool selected = option.filter == selectedFilter;
          return ChoiceChip(
            label: Text(option.label),
            selected: selected,
            onSelected: isDisabled ? null : (_) => onChanged(option.filter),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            selectedColor: const Color(0x334F46E5),
            disabledColor: Colors.white.withValues(alpha: 0.04),
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
    );
  }
}

class _ConstellationPanel extends StatelessWidget {
  const _ConstellationPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _ConstellationMessageState extends StatelessWidget {
  const _ConstellationMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: const Color(0xFF8B84FF), size: 32),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedStarNode extends StatelessWidget {
  const _FeedStarNode({
    required this.star,
    required this.color,
    required this.size,
    required this.isMine,
    required this.onTap,
  });

  final Star star;
  final Color color;
  final double size;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSeen = star.isSeen;
    final Color markerColor = isMine ? const Color(0xFFF9A8D4) : color;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isMine || isSeen)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF3B1F3C).withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isMine
                      ? markerColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                isMine ? '내 별' : '읽음',
                style: TextStyle(
                  color: isMine ? const Color(0xFFFFD7EA) : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Container(
            width: isMine ? size + 12 : size,
            height: isMine ? size + 12 : size,
            padding: EdgeInsets.all(isMine ? 4 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMine
                  ? const Color(0xFF0F1020).withValues(alpha: 0.72)
                  : null,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: markerColor.withValues(alpha: isMine ? 0.5 : 0.56),
                  blurRadius: isMine ? 30 : 16,
                ),
              ],
              border: Border.all(
                color: isMine
                    ? markerColor.withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: 0.1),
                width: isMine ? 2 : 1,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    color,
                    color.withValues(alpha: isSeen ? 0.03 : 0.12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 86,
            child: Text(
              _compactStarLabel(star),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarDetailPage extends StatefulWidget {
  const _StarDetailPage({
    required this.initialStar,
    required this.userId,
    required this.isPreviewMode,
  });

  final Star initialStar;
  final String userId;
  final bool isPreviewMode;

  @override
  State<_StarDetailPage> createState() => _StarDetailPageState();
}

class _StarDetailPageState extends State<_StarDetailPage> {
  late Star _star = widget.initialStar;
  bool _isLoading = true;
  bool _isSendingReaction = false;
  String? _loadErrorMessage;
  List<ReactionType> _reactionTypes = const <ReactionType>[];
  ReactionType? _sentReactionType;

  ConstellationRepository get _constellationRepository =>
      ConstellationRepository(
        dataSource: SupabaseConstellationDataSource(
          client: Supabase.instance.client,
        ),
      );

  ReactionRepository get _reactionRepository => ReactionRepository(
    dataSource: SupabaseReactionDataSource(client: Supabase.instance.client),
  );

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0B14),
        body: Stack(
          children: <Widget>[
            const _DetailBackdrop(),
            SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC7D2FE),
                      ),
                    )
                  : _loadErrorMessage != null
                  ? _DetailErrorState(
                      message: _loadErrorMessage!,
                      onBack: _close,
                      onRetry: _loadDetail,
                    )
                  : _buildDetailContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context) {
    final bool isMine = _star.userId == widget.userId;
    final List<String> tagLabels = _starTagLabels(_star);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white.withValues(alpha: 0.68),
            tooltip: '뒤로',
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: _DetailEmotionOrb(
            label: _detailStarLabel(_star),
            color: _colorForStar(_star),
            isMine: isMine,
          ),
        ),
        const SizedBox(height: 54),
        Text(
          '"${_star.content}"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '${_bucketLabel(_star.timeBucket)} ${_formatTime(_star.createdAt)} · ${isMine ? '내 별' : '익명'} · ${_star.reactionCount}명이 리액션',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.54),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (isMine) const _DetailPill(label: '내 별'),
            for (final String label in tagLabels) _DetailPill(label: label),
            _DetailPill(label: _bucketPillLabel(_star.timeBucket)),
          ],
        ),
        const SizedBox(height: 44),
        const _WarmReactionDivider(),
        const SizedBox(height: 26),
        Text(
          _reactionGuideText(isMine: isMine, star: _star),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        _ReactionGrid(
          reactionTypes: _orderedReactionTypes,
          isEnabled: _star.isReactable && !_isSendingReaction,
          sentReactionType: _sentReactionType,
          onSelect: _sendReaction,
        ),
        const SizedBox(height: 30),
        Text(
          '자유 텍스트 전송 불가 · 리액션 4종만 가능 · 어뷰징 방지',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.32),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    if (widget.isPreviewMode) {
      setState(() {
        _star = widget.initialStar;
        _reactionTypes = _previewReactionTypes;
        _isLoading = false;
      });
      return;
    }

    try {
      final Star detail = await _constellationRepository.fetchStarById(
        widget.initialStar.starId,
      );
      final Star resolvedDetail = await _withResolvedTagNamesForStar(detail);
      await _constellationRepository.markStarSeen(
        starId: widget.initialStar.starId,
        userId: widget.userId,
      );
      final List<ReactionType> reactionTypes = await _reactionRepository
          .fetchReactionTypes();
      if (!mounted) {
        return;
      }
      setState(() {
        _star = resolvedDetail;
        _reactionTypes = reactionTypes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadErrorMessage = _mapDetailLoadErrorToMessage(error);
      });
    }
  }

  Future<void> _sendReaction(ReactionType reactionType) async {
    if (_isSendingReaction || !_star.isReactable) {
      return;
    }

    if (widget.isPreviewMode) {
      setState(() {
        _sentReactionType = reactionType;
      });
      _showSnackBar('${reactionType.labelKo} 리액션을 보냈어요.');
      return;
    }

    setState(() {
      _isSendingReaction = true;
    });

    try {
      final SendReactionResult result = await _reactionRepository.sendReaction(
        starId: _star.starId,
        reactionTypeId: reactionType.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSendingReaction = false;
        _sentReactionType = reactionType;
        _star = _copyStarWithReactionCount(_star, result.reactionCount);
      });
      _showSnackBar('${reactionType.labelKo} 리액션을 보냈어요.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSendingReaction = false;
      });
      _showSnackBar(_mapReactionErrorToMessage(error));
    }
  }

  List<ReactionType> get _orderedReactionTypes {
    final Map<String, ReactionType> byCode = <String, ReactionType>{
      for (final ReactionType type in _reactionTypes) type.code: type,
    };
    final List<ReactionType> ordered = <ReactionType>[
      for (final String code in _reactionOrder)
        if (byCode[code] != null) byCode[code]!,
    ];
    if (ordered.isNotEmpty) {
      return ordered;
    }
    return _reactionTypes;
  }

  void _close() {
    Navigator.of(context).pop(_star);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapDetailLoadErrorToMessage(Object error) {
    if (error is ConstellationException) {
      switch (error.code) {
        case ConstellationErrorCode.unauthorized:
          return '익명 로그인 상태를 확인한 뒤 다시 시도해 주세요.';
        case ConstellationErrorCode.forbidden:
          return '프로필 또는 권한 상태 때문에 이 별을 볼 수 없습니다.';
        case ConstellationErrorCode.starNotFound:
          return '이 별은 더 이상 볼 수 없습니다.';
        case ConstellationErrorCode.blockedRelationship:
          return '차단 관계 때문에 이 별을 볼 수 없습니다.';
        case ConstellationErrorCode.invalidArgument:
          return '별 정보가 올바르지 않습니다.';
        default:
          return error.message ?? '별을 여는 중 문제가 발생했습니다.';
      }
    }
    if (error is ReactionException) {
      return mapReactionErrorCodeToMessage(errorCode: error.code);
    }
    return '별을 여는 중 문제가 발생했습니다.';
  }

  String _mapReactionErrorToMessage(Object error) {
    if (error is ReactionException) {
      return mapReactionErrorCodeToMessage(errorCode: error.code);
    }
    return mapReactionErrorCodeToMessage(
      errorCode: ReactionErrorCode.internalError,
    );
  }
}

class _DetailBackdrop extends StatelessWidget {
  const _DetailBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF0A0B14),
              gradient: RadialGradient(
                center: Alignment(0, -0.28),
                radius: 0.92,
                colors: <Color>[Color(0x332F2034), Color(0xFF0A0B14)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 108,
          top: 105,
          child: _TinyGlowDot(size: 5, opacity: 0.45),
        ),
        Positioned(
          right: 82,
          top: 338,
          child: _TinyGlowDot(size: 7, opacity: 0.34),
        ),
        Positioned(
          left: 40,
          bottom: 80,
          child: _TinyGlowDot(size: 3, opacity: 0.28),
        ),
      ],
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white.withValues(alpha: 0.68),
              tooltip: '뒤로',
            ),
          ),
          Expanded(
            child: _ConstellationMessageState(
              icon: Icons.error_outline,
              title: '별을 열 수 없습니다',
              message: message,
              actionLabel: '다시 시도',
              onAction: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailEmotionOrb extends StatelessWidget {
  const _DetailEmotionOrb({
    required this.label,
    required this.color,
    required this.isMine,
  });

  final String label;
  final Color color;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      height: 154,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.96),
            color.withValues(alpha: 0.58),
            color.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.34),
            blurRadius: 58,
            spreadRadius: 8,
          ),
        ],
        border: isMine
            ? Border.all(color: const Color(0xFFF9A8D4), width: 2)
            : null,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x66514A66),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WarmReactionDivider extends StatelessWidget {
  const _WarmReactionDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'WARM REACTION',
            style: TextStyle(
              color: const Color(0xFFA7B0CB).withValues(alpha: 0.66),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _ReactionGrid extends StatelessWidget {
  const _ReactionGrid({
    required this.reactionTypes,
    required this.isEnabled,
    required this.sentReactionType,
    required this.onSelect,
  });

  final List<ReactionType> reactionTypes;
  final bool isEnabled;
  final ReactionType? sentReactionType;
  final ValueChanged<ReactionType> onSelect;

  @override
  Widget build(BuildContext context) {
    if (reactionTypes.isEmpty) {
      return const _ReactionUnavailableState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reactionTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.72,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ReactionType reactionType = reactionTypes[index];
        return _ReactionCard(
          reactionType: reactionType,
          isEnabled: isEnabled,
          isSelected: sentReactionType?.id == reactionType.id,
          onTap: () => onSelect(reactionType),
        );
      },
    );
  }
}

class _ReactionUnavailableState extends StatelessWidget {
  const _ReactionUnavailableState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF141528),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        '사용 가능한 리액션을 불러오지 못했습니다.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.62),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReactionCard extends StatelessWidget {
  const _ReactionCard({
    required this.reactionType,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
  });

  final ReactionType reactionType;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled || isSelected ? 1 : 0.42,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF242744)
                  : const Color(0xFF141528),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? const Color(0x66818CF8)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF24263D),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Icon(
                    _iconForReaction(reactionType),
                    color: const Color(0xFFDDE4FF),
                    size: 25,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  reactionType.labelKo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (reactionType.code == 'WARM_TEA') ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    '작은 온기 보내기',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyGlowDot extends StatelessWidget {
  const _TinyGlowDot({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white.withValues(alpha: opacity),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _ConstellationLinePainter extends CustomPainter {
  const _ConstellationLinePainter();

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

class _FilterOption {
  const _FilterOption({required this.label, required this.filter});

  final String label;
  final FeedFilter filter;
}

const List<_FilterOption> _filterOptions = <_FilterOption>[
  _FilterOption(label: '전체', filter: FeedFilter.all),
  _FilterOption(label: '새벽', filter: FeedFilter.dawn),
  _FilterOption(label: '아침', filter: FeedFilter.morning),
  _FilterOption(label: '낮', filter: FeedFilter.day),
  _FilterOption(label: '저녁', filter: FeedFilter.evening),
  _FilterOption(label: '밤', filter: FeedFilter.night),
];

const List<String> _reactionOrder = <String>[
  'WARM_TEA',
  'HUG',
  'YOU_DID_WELL',
  'WITH_YOU',
];

const List<ReactionType> _previewReactionTypes = <ReactionType>[
  ReactionType(id: 1, code: 'WARM_TEA', labelKo: '따뜻한 차', icon: 'tea'),
  ReactionType(id: 2, code: 'HUG', labelKo: '안아드려요', icon: 'hug'),
  ReactionType(id: 3, code: 'YOU_DID_WELL', labelKo: '고생했어요', icon: 'clover'),
  ReactionType(id: 4, code: 'WITH_YOU', labelKo: '함께해요', icon: 'stars'),
];

const List<Alignment> _starAlignments = <Alignment>[
  Alignment(-0.25, -0.1),
  Alignment(0.18, -0.38),
  Alignment(0.52, 0.1),
  Alignment(-0.6, 0.28),
  Alignment(0.7, -0.7),
  Alignment(-0.72, -0.54),
  Alignment(0.05, 0.64),
  Alignment(0.66, 0.62),
  Alignment(-0.28, -0.72),
  Alignment(-0.8, 0.72),
];

Map<int, String>? _emotionTagNameByIdCache;

final List<Star> _previewStars = <Star>[
  Star(
    starId: 'preview-mine',
    userId: 'preview-user',
    content: '오늘은 조금 지쳤지만 그래도 잘 버텼어요.',
    tagIds: const <int>[2, 9],
    tagNames: const <String>['지침', '버팀'],
    timeBucket: 'night',
    reactionCount: 3,
    createdAt: DateTime(2026, 4, 11, 23, 28),
    expiresAt: null,
    relationScore: 42,
    isSeen: true,
    visibilityStatus: 'public',
    isDeleted: false,
    isExpired: false,
    isReactable: false,
    diversityKey: 'preview:mine',
  ),
  Star(
    starId: 'preview-similar',
    userId: 'preview-other-1',
    content: '마음이 자꾸 조용해져서 작은 위로가 필요했어요.',
    tagIds: const <int>[4, 10],
    tagNames: const <String>['외로움', '위로받고 싶음'],
    timeBucket: 'night',
    reactionCount: 2,
    createdAt: DateTime(2026, 4, 11, 22, 4),
    expiresAt: null,
    relationScore: 31,
    isSeen: false,
    visibilityStatus: 'public',
    isDeleted: false,
    isExpired: false,
    isReactable: true,
    diversityKey: 'preview:similar',
  ),
  Star(
    starId: 'preview-calm',
    userId: 'preview-other-2',
    content: '조금 잔잔해진 밤이라 이 감각을 남겨두고 싶어요.',
    tagIds: const <int>[8],
    tagNames: const <String>['잔잔함'],
    timeBucket: 'evening',
    reactionCount: 5,
    createdAt: DateTime(2026, 4, 11, 20, 16),
    expiresAt: null,
    relationScore: 26,
    isSeen: false,
    visibilityStatus: 'public',
    isDeleted: false,
    isExpired: false,
    isReactable: true,
    diversityKey: 'preview:calm',
  ),
  Star(
    starId: 'preview-anxiety',
    userId: 'preview-other-3',
    content: '내일을 생각하면 자꾸 조마조마해져요.',
    tagIds: const <int>[6],
    tagNames: const <String>['불안'],
    timeBucket: 'dawn',
    reactionCount: 1,
    createdAt: DateTime(2026, 4, 11, 3, 5),
    expiresAt: null,
    relationScore: 18,
    isSeen: false,
    visibilityStatus: 'public',
    isDeleted: false,
    isExpired: false,
    isReactable: true,
    diversityKey: 'preview:anxiety',
  ),
];

Alignment _alignmentForIndex(int index) {
  return _starAlignments[index % _starAlignments.length];
}

Color _colorForStar(Star star) {
  switch (star.timeBucket) {
    case 'dawn':
      return const Color(0xFFA78BFA);
    case 'morning':
      return const Color(0xFFFBBF24);
    case 'day':
      return const Color(0xFF60A5FA);
    case 'evening':
      return const Color(0xFFF472B6);
    case 'night':
      return const Color(0xFF818CF8);
    default:
      return const Color(0xFF34D399);
  }
}

double _sizeForStar(Star star) {
  final double scoreSize = math.min(star.relationScore, 60) / 60 * 12;
  final double reactionSize = math.min(star.reactionCount, 8).toDouble();
  return 14 + scoreSize + reactionSize;
}

String _compactStarLabel(Star star) {
  final List<String> tags = _starTagLabels(star);
  if (tags.isEmpty) {
    return _bucketLabel(star.timeBucket);
  }
  if (tags.length == 1) {
    return tags.first;
  }
  return '${tags.first} +${tags.length - 1}';
}

String _detailStarLabel(Star star) {
  final List<String> tags = _starTagLabels(star);
  if (tags.isEmpty) {
    return _bucketLabel(star.timeBucket);
  }
  if (tags.length == 1) {
    return tags.first;
  }
  if (tags.length == 2) {
    return '${tags.first}\n${tags[1]}';
  }
  return '${tags.first}\n${tags[1]} +${tags.length - 2}';
}

List<String> _starTagLabels(Star star) {
  if (star.tagNames.isNotEmpty) {
    return star.tagNames.map((String tagName) => '#$tagName').toList();
  }
  return star.tagIds.map((int tagId) => 'tag $tagId').toList();
}

Future<List<Star>> _withResolvedTagNames(List<Star> stars) async {
  if (!stars.any(_needsResolvedTagNames)) {
    return stars;
  }
  final Map<int, String> tagNameById = await _fetchEmotionTagNameById();
  if (tagNameById.isEmpty) {
    return stars;
  }
  return stars
      .map((Star star) => _copyStarWithResolvedTagNames(star, tagNameById))
      .toList(growable: false);
}

Future<Star> _withResolvedTagNamesForStar(Star star) async {
  if (!_needsResolvedTagNames(star)) {
    return star;
  }
  final Map<int, String> tagNameById = await _fetchEmotionTagNameById();
  if (tagNameById.isEmpty) {
    return star;
  }
  return _copyStarWithResolvedTagNames(star, tagNameById);
}

bool _needsResolvedTagNames(Star star) {
  return star.tagIds.isNotEmpty && star.tagNames.length < star.tagIds.length;
}

Future<Map<int, String>> _fetchEmotionTagNameById() async {
  final Map<int, String>? cached = _emotionTagNameByIdCache;
  if (cached != null) {
    return cached;
  }

  try {
    final List<EmotionTag> tags = await EmotionRepository(
      dataSource: SupabaseEmotionDataSource(client: Supabase.instance.client),
    ).fetchEmotionTags();
    final Map<int, String> tagNameById = <int, String>{
      for (final EmotionTag tag in tags)
        if (tag.nameKo.isNotEmpty) tag.id: tag.nameKo,
    };
    _emotionTagNameByIdCache = tagNameById;
    return tagNameById;
  } catch (_) {
    return const <int, String>{};
  }
}

Star _copyStarWithResolvedTagNames(Star star, Map<int, String> tagNameById) {
  final List<String> resolvedTagNames = star.tagIds
      .map((int tagId) => tagNameById[tagId])
      .whereType<String>()
      .toList(growable: false);

  if (resolvedTagNames.length <= star.tagNames.length) {
    return star;
  }

  return Star(
    starId: star.starId,
    userId: star.userId,
    content: star.content,
    tagIds: star.tagIds,
    tagNames: resolvedTagNames,
    timeBucket: star.timeBucket,
    reactionCount: star.reactionCount,
    createdAt: star.createdAt,
    expiresAt: star.expiresAt,
    relationScore: star.relationScore,
    isSeen: star.isSeen,
    visibilityStatus: star.visibilityStatus,
    isDeleted: star.isDeleted,
    isExpired: star.isExpired,
    isReactable: star.isReactable,
    diversityKey: star.diversityKey,
  );
}

String _reactionGuideText({required bool isMine, required Star star}) {
  if (star.isReactable) {
    return '다정한 리액션만 보낼 수 있어요';
  }
  if (isMine) {
    return '내 별에는 다른 사람의 리액션만 쌓여요';
  }
  return '이 별에는 리액션을 보낼 수 없어요';
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
      return '시간 미상';
  }
}

String _bucketPillLabel(String bucket) {
  switch (bucket) {
    case 'dawn':
      return '달 새벽';
    case 'morning':
      return '아침 햇살';
    case 'day':
      return '낮의 별';
    case 'evening':
      return '저녁 노을';
    case 'night':
      return '밤의 별';
    default:
      return '시간 미상';
  }
}

String _formatTime(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

IconData _iconForReaction(ReactionType reactionType) {
  switch (reactionType.code) {
    case 'WARM_TEA':
      return Icons.local_cafe_outlined;
    case 'HUG':
      return Icons.favorite_border_rounded;
    case 'YOU_DID_WELL':
      return Icons.auto_awesome_rounded;
    case 'WITH_YOU':
      return Icons.nights_stay_outlined;
    default:
      return Icons.favorite_outline_rounded;
  }
}

Star _copyStarWithReactionCount(Star star, int reactionCount) {
  return Star(
    starId: star.starId,
    userId: star.userId,
    content: star.content,
    tagIds: star.tagIds,
    tagNames: star.tagNames,
    timeBucket: star.timeBucket,
    reactionCount: reactionCount,
    createdAt: star.createdAt,
    expiresAt: star.expiresAt,
    relationScore: star.relationScore,
    isSeen: true,
    visibilityStatus: star.visibilityStatus,
    isDeleted: star.isDeleted,
    isExpired: star.isExpired,
    isReactable: false,
    diversityKey: star.diversityKey,
  );
}
