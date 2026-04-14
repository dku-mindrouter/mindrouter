import 'package:flutter/material.dart';

class ConstellationPage extends StatefulWidget {
  const ConstellationPage({super.key});

  @override
  State<ConstellationPage> createState() => _ConstellationPageState();
}

class _ConstellationPageState extends State<ConstellationPage> {
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
                  const Positioned.fill(
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
