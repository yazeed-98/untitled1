import 'package:flutter/material.dart';

class ShinyIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;       // قطر الدائرة
  final double iconSize;   // حجم الأيقونة
  final List<Color>? colors;

  const ShinyIconBadge({
    super.key,
    required this.icon,
    this.size = 46,
    this.iconSize = 24,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final g = colors ?? [Colors.blue.shade500, Colors.indigo.shade600];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: g,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: g.last.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, color: Colors.white, size: iconSize)),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
