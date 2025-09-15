import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/starss.dart';
import '../clasess/rating_sheet.dart';
import '../clasess/report_dialog.dart';
import 'favorite_toggle.dart';

class PlaceCard extends StatefulWidget {
  final String title;
  final String city;
  final String category;
  final String imageUrl;
  final double rating;
  final int ratingCount;

  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback onTap;

  final VoidCallback? onRate;
  final VoidCallback? onReport;

  final DocumentReference<Map<String, dynamic>> ref;
  final bool isAdmin;

  const PlaceCard({
    super.key,
    required this.title,
    required this.city,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.ratingCount,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onTap,
    required this.ref,
    this.onRate,
    this.onReport,
    this.isAdmin = false,
  });

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // صورة المكان
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(widget.imageUrl, height: 150, fit: BoxFit.cover)
                    : Container(height: 150, color: Colors.grey.shade300),
              ),

              // المحتوى النصي
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    // المدينة والنوع
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.blueGrey[400]),
                        const SizedBox(width: 4),
                        Text(widget.city, style: TextStyle(color: Colors.blueGrey[700])),
                        const SizedBox(width: 10),
                        Text(widget.category, style: TextStyle(color: Colors.blueGrey[700])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // التقييم النجمي
                    Stars(rating: widget.rating, size: 18),
                  ],
                ),
              ),

              // المفضلة + التقييم + البلاغ أو تعديل/حذف
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: widget.isAdmin
                      ? [
                    // أدمن: تعديل
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("تعديل"),
                        onPressed: () {
                          // TODO: تعديل البيانات
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // أدمن: حذف
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text("حذف"),
                        onPressed: () async {
                          await widget.ref.delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("تم الحذف بنجاح")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      ),
                    ),
                  ]
                      : [
                    // مستخدم: المفضلة
                    FavoriteToggle(
                      isFav: widget.isFavorite,
                      onChanged: widget.onFavoriteChanged,
                      bgColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 10),
                    // زر التقييم
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.star_rate),
                        label: const Text("قيّم"),
                        onPressed: widget.onRate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // زر البلاغ
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flag),
                        label: const Text("بلاغ"),
                        onPressed: widget.onReport,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
