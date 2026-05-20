import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/app_panel_card.dart';
import '../data/profile_repository.dart';
import '../data/supabase_profile_data_source.dart';
import '../domain/my_star_history_item.dart';

class MyStarsPage extends StatefulWidget {
  const MyStarsPage({
    super.key,
    required this.onBack,
    required this.isPreviewMode,
  });

  final VoidCallback onBack;
  final bool isPreviewMode;

  @override
  State<MyStarsPage> createState() => _MyStarsPageState();
}

class _MyStarsPageState extends State<MyStarsPage> {
  late Future<List<MyStarHistoryItem>> _future = _loadStars();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _future = _loadStars();
        });
        await _future;
      },
      child: FutureBuilder<List<MyStarHistoryItem>>(
        future: _future,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<MyStarHistoryItem>> snapshot,
            ) {
              final List<Widget> children = <Widget>[
                _SubPageHeader(title: '내가 띄운 별', onBack: widget.onBack),
                const SizedBox(height: 12),
                Text(
                  '내가 남긴 감정 글과 받은 리액션 수를 모아볼 수 있어요.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.64),
                  ),
                ),
                const SizedBox(height: 24),
              ];

              if (snapshot.connectionState != ConnectionState.done) {
                children.add(
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(
                        color: Color(0xFF818CF8),
                      ),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                children.add(
                  AppPanelCard(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    borderColor: Colors.white.withValues(alpha: 0.06),
                    child: Text(
                      '내 별 목록을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              } else {
                final List<MyStarHistoryItem> stars =
                    snapshot.data ?? const <MyStarHistoryItem>[];
                if (stars.isEmpty) {
                  children.add(
                    AppPanelCard(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      borderColor: Colors.white.withValues(alpha: 0.06),
                      child: Text(
                        '아직 띄운 별이 없어요. 오늘 탭에서 감정을 기록하면 이곳에 쌓입니다.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                } else {
                  children.addAll(
                    stars.map(
                      (MyStarHistoryItem star) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MyStarCard(star: star),
                      ),
                    ),
                  );
                }
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                children: children,
              );
            },
      ),
    );
  }

  Future<List<MyStarHistoryItem>> _loadStars() async {
    if (widget.isPreviewMode) {
      return _previewStars;
    }

    final SupabaseClient client = Supabase.instance.client;
    final ProfileRepository repository = ProfileRepository(
      dataSource: SupabaseProfileDataSource(client: client),
    );
    return repository.fetchMyStars();
  }
}

class _SubPageHeader extends StatelessWidget {
  const _SubPageHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MyStarCard extends StatelessWidget {
  const _MyStarCard({required this.star});

  final MyStarHistoryItem star;

  @override
  Widget build(BuildContext context) {
    final String tagLabel = star.tagNames.isEmpty
        ? '#감정 기록'
        : star.tagNames.map((String tag) => '#$tag').join(' ');

    return AppPanelCard(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      const Color(0xFF7656B8).withValues(alpha: 0.92),
                      const Color(0xFF7656B8).withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      tagLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dateText(star.createdAt)} · ${_bucketLabel(star.timeBucket)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.46),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(star: star),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"${star.content}"',
            style: const TextStyle(
              color: Colors.white,
              height: 1.45,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Icon(
                Icons.favorite_border,
                color: Colors.white.withValues(alpha: 0.54),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${star.reactionCount}명이 리액션',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 12,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.star});

  final MyStarHistoryItem star;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (star.isDeleted) {
      label = '삭제됨';
      color = const Color(0xFF94A3B8);
    } else if (star.isExpired) {
      label = '보관됨';
      color = const Color(0xFFF59E0B);
    } else {
      label = '공개 중';
      color = const Color(0xFF22C55E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
      return '기록';
  }
}

String _dateText(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$month.$day $hour:$minute';
}

final List<MyStarHistoryItem> _previewStars = <MyStarHistoryItem>[
  MyStarHistoryItem(
    id: 'preview-1',
    content: '오늘은 마음이 조금 무거웠지만 그래도 기록해 봅니다.',
    tagNames: const <String>['우울함', '위로받고 싶음'],
    timeBucket: 'night',
    reactionCount: 3,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    createdLocalDate: DateTime.now(),
    visibilityStatus: 'public',
    isDeleted: false,
    isExpired: false,
  ),
  MyStarHistoryItem(
    id: 'preview-2',
    content: '작은 기대감이 생긴 하루였어요.',
    tagNames: const <String>['기대감/활력'],
    timeBucket: 'evening',
    reactionCount: 1,
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    createdLocalDate: DateTime.now().subtract(const Duration(days: 1)),
    visibilityStatus: 'public',
    isDeleted: false,
    isExpired: true,
  ),
];
