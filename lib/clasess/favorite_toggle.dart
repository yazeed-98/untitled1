// lib/clasess/favorite_toggle.dart
import 'package:flutter/material.dart';

/// زر قلب (مفضّلة) قابل لإعادة الاستخدام.
/// لا يدير حالة داخلية — خليه يستقبل isFav وينادي onChanged(!isFav).
class FavoriteToggle extends StatelessWidget {
  final bool isFav;
  final ValueChanged<bool> onChanged;

  /// حجم الدائرة الكلي (وليس الأيقونة)
  final double size;

  /// لون القلب عند التفعيل/التعطيل
  final Color activeColor;
  final Color inactiveColor;

  /// لون خلفية الزر (عادةً أبيض شفاف فوق الصور)
  final Color bgColor;

  /// Tooltip لنص المساعدة
  final String tooltip;

  const FavoriteToggle({
    super.key,
    required this.isFav,
    required this.onChanged,
    this.size = 40,
    this.activeColor = Colors.redAccent,
    this.inactiveColor = Colors.black54,
    this.bgColor = const Color(0xE6FFFFFF), // أبيض شبه شفاف
    this.tooltip = 'مفضلة',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onChanged(!isFav),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: EdgeInsets.all(size * 0.18),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? activeColor : inactiveColor,
              size: size * 0.62,
            ),
          ),
        ),
      ),
    );
  }
}
