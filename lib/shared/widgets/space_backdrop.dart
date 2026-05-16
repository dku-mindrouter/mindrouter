import 'package:flutter/material.dart';

class SpaceBackdrop extends StatelessWidget {
  const SpaceBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
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
        const Positioned(
          top: -80,
          left: -60,
          child: _GlowOrb(size: 240, color: Color(0x803B82F6)),
        ),
        const Positioned(
          bottom: 40,
          right: -50,
          child: _GlowOrb(size: 220, color: Color(0x665B21B6)),
        ),
        const Positioned(
          top: 200,
          right: 40,
          child: _GlowOrb(size: 140, color: Color(0x664DD0E1)),
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
