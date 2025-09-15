import 'package:flutter/material.dart';

class Stars extends StatelessWidget {
  final double rating; // 0..5
  final double size;
  const Stars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final filled = rating.floor();
    final hasHalf = (rating - filled) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (i < filled) {
          icon = Icons.star;
        } else if (i == filled && hasHalf) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: size, color: Colors.amber[700]);
      }),
    );
  }
}
