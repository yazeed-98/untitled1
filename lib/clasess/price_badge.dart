// lib/clasess/price_badge.dart
import 'package:flutter/material.dart';

/// أدوات مساعدة خاصة بالسعر
class PriceUtils {
  /// نص عربي جاهز
  static String label(int level) {
    switch (level) {
      case 1:
        return 'رخيص • \$';
      case 2:
        return 'متوسط • \$\$';
      default:
        return 'غالي • \$\$\$';
    }
  }

  /// فقط رموز الدولار
  static String symbols(int level) {
    if (level <= 1) return '\$';
    if (level == 2) return '\$\$';
    return '\$\$\$';
  }

  /// لون مناسب حسب المستوى
  static Color color(int level) {
    if (level == 1) return Colors.green;
    if (level == 2) return Colors.orange;
    return Colors.redAccent;
  }
}

/// شارة/Chip للسعر يمكن استخدامها داخل البطاقات أو التفاصيل
class PriceBadge extends StatelessWidget {
  final int level;         // 1..3
  final bool showText;     // true = 'رخيص • $' / false = '$$'
  final EdgeInsets padding;
  final double iconSize;
  final TextStyle? textStyle;

  const PriceBadge({
    super.key,
    required this.level,
    this.showText = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.iconSize = 18,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final c = PriceUtils.color(level);
    final label = showText ? PriceUtils.label(level) : PriceUtils.symbols(level);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_money, size: 18, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: textStyle ??
                TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
          ),
        ],
      ),
    );
  }
}
