import 'package:flutter/material.dart';

import '../../../shared/widgets/app_panel_card.dart';

class TodayMissionPage extends StatelessWidget {
  const TodayMissionPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 160),
          children: <Widget>[
            Row(
              children: <Widget>[
                _RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  label: '프로필로 돌아가기',
                  onPressed: onBack,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "TODAY'S MISSION",
                      style: TextStyle(
                        color: Color(0xFFD6DBEA),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 34),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFFC02B), Color(0xFFFF720D)],
                    ),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '햇살과 함께\n10분 걷기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text(
              '텅 빈 마음을 채우는 가장 쉬운 방법은 밖으로 나가 가볍게 몸을 움직이는 거예요. 세로토닌을 깨워 무기력함을 이겨내봐요.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 16,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 38),
            AppPanelCard(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
              backgroundColor: const Color(0xE51B1D34),
              borderColor: Colors.white.withValues(alpha: 0.08),
              borderRadius: 28,
              child: Column(
                children: const <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '체크리스트',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF9BAAD0),
                        size: 17,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '10 mins',
                        style: TextStyle(
                          color: Color(0xFF9BAAD0),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _ChecklistItem(label: '편안한 신발 신고 밖으로 나가기'),
                  SizedBox(height: 20),
                  _ChecklistItem(label: '좋아하는 음악을 들으며 10분 이상 걷기'),
                  SizedBox(height: 20),
                  _ChecklistItem(label: '크게 숨을 들이마시며 하늘 한 번 보기'),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 116,
          child: FilledButton.icon(
            onPressed: () => _showPlaceholder(context),
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: const Text('미션 시작하기'),
            style:
                FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A0C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 19),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ).copyWith(
                  backgroundColor: const WidgetStatePropertyAll<Color>(
                    Color(0xFFFF7A0C),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  void _showPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('미션 시작은 추후 타이머/완료 저장 정책과 함께 연결할 예정이에요.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1B1D32),
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

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8EA1CA), width: 1.2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAEB8D4),
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
