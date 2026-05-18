import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/app_panel_card.dart';
import '../data/comfort_repository.dart';
import '../data/supabase_comfort_data_source.dart';
import '../domain/comfort_exception.dart';
import '../domain/comfort_letter.dart';
import '../domain/comfort_notification.dart';

class ComfortPage extends StatefulWidget {
  const ComfortPage({super.key});

  @override
  State<ComfortPage> createState() => _ComfortPageState();
}

class _ComfortPageState extends State<ComfortPage> {
  late final ComfortRepository _repository = ComfortRepository(
    dataSource: SupabaseComfortDataSource(client: Supabase.instance.client),
  );

  late Future<List<ComfortNotification>> _future = _fetchNotifications();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _future = _fetchNotifications();
        });
        await _future;
      },
      child: FutureBuilder<List<ComfortNotification>>(
        future: _future,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<ComfortNotification>> snapshot,
            ) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF818CF8)),
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  children: <Widget>[
                    const _Header(),
                    const SizedBox(height: 24),
                    AppPanelCard(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      borderColor: Colors.white.withValues(alpha: 0.06),
                      child: Text(
                        _mapErrorToMessage(snapshot.error),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final List<ComfortNotification> items = snapshot.data ?? const [];
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                children: <Widget>[
                  const _Header(),
                  const SizedBox(height: 24),
                  if (items.isEmpty)
                    AppPanelCard(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      borderColor: Colors.white.withValues(alpha: 0.06),
                      child: Text(
                        '아직 도착한 위로가 없어요. 누군가의 반응이나 위로가 오면 이곳에 표시됩니다.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    ...items.map(
                      (ComfortNotification item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _NotificationCard(
                          item: item,
                          onTap: item.notificationType == 'letter'
                              ? () => _openLetter(item.id)
                              : null,
                        ),
                      ),
                    ),
                ],
              );
            },
      ),
    );
  }

  Future<List<ComfortNotification>> _fetchNotifications() {
    return _repository.fetchComfortNotifications();
  }

  Future<void> _openLetter(String letterId) async {
    try {
      final ComfortLetter letter = await _repository.openLetter(
        letterId: letterId,
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => _LetterDialog(letter: letter),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _future = _fetchNotifications();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapErrorToMessage(error))));
    }
  }

  String _mapErrorToMessage(Object? error) {
    if (error is ComfortException) {
      switch (error.code) {
        case ComfortErrorCode.letterNotFound:
          return '편지를 찾을 수 없어요.';
        case ComfortErrorCode.unauthorized:
          return '로그인 정보를 확인할 수 없어요. 앱을 다시 실행해 주세요.';
        case ComfortErrorCode.forbidden:
          return '위로 내역을 조회할 권한이 없어요.';
      }
    }
    return '위로 내역을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          '내 별에 도착한 실제 리액션과 위로를 이곳에서 확인할 수 있어요.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.64),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, this.onTap});

  final ComfortNotification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = _accentColor(item.accentColor);
    final IconData icon = _iconFor(item.icon);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AppPanelCard(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        borderColor: item.isOpened
            ? Colors.white.withValues(alpha: 0.06)
            : color.withValues(alpha: 0.28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: color),
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
                        _formatRelativeTime(item.eventAt),
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
                    item.body,
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
    );
  }
}

class _LetterDialog extends StatelessWidget {
  const _LetterDialog({required this.letter});

  final ComfortLetter letter;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF17182A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        '익명 편지가 도착했어요',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '"${letter.starContent}" 별에 도착한 편지',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.52)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                letter.content,
                style: const TextStyle(color: Colors.white, height: 1.6),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF818CF8),
            foregroundColor: Colors.white,
          ),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

IconData _iconFor(String icon) {
  switch (icon) {
    case 'tea':
      return Icons.local_cafe_outlined;
    case 'coffee':
      return Icons.coffee_outlined;
    case 'hug':
      return Icons.favorite_border;
    case 'clover':
      return Icons.auto_awesome;
    case 'stars':
      return Icons.nightlight_round;
    case 'letter':
      return Icons.mail_outline_rounded;
    case 'auto_awesome':
      return Icons.auto_awesome_outlined;
    default:
      return Icons.notifications_none_rounded;
  }
}

Color _accentColor(String accent) {
  switch (accent) {
    case 'amber':
      return const Color(0xFFFBBF24);
    case 'coffee':
      return const Color(0xFFC08457);
    case 'rose':
      return const Color(0xFFFB7185);
    case 'sky':
      return const Color(0xFF38BDF8);
    case 'violet':
      return const Color(0xFF818CF8);
    case 'indigo':
      return const Color(0xFFA5B4FC);
    default:
      return const Color(0xFFA5B4FC);
  }
}

String _formatRelativeTime(DateTime eventAt) {
  final Duration difference = DateTime.now().difference(eventAt.toLocal());
  if (difference.inMinutes < 1) {
    return '방금';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}시간 전';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}일 전';
  }
  final DateTime local = eventAt.toLocal();
  return '${local.month}/${local.day}';
}
