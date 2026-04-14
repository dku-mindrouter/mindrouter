import 'package:flutter/material.dart';

import '../../../shared/widgets/app_panel_card.dart';

class ComfortPage extends StatelessWidget {
  const ComfortPage({super.key});

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
            child: AppPanelCard(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              borderColor: Colors.white.withValues(alpha: 0.06),
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
