import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/starss.dart';
import 'edit_place_page.dart';
import 'favorite_toggle.dart';

class PlaceCard extends StatefulWidget {
  final String title;
  final String city;
  final String category;
  final String? placeName; // 👈 اسم المكان (مطعم/فندق) إذا موجود
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
    this.placeName, // 👈 اختياري
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
              // 🖼️ صورة المكان
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                child: (widget.imageUrl.isNotEmpty)
                    ? Image.network(widget.imageUrl,
                    height: 150, fit: BoxFit.cover)
                    : Image.asset("assets/images/placeholder.png",
                    height: 150, fit: BoxFit.cover),
              ),

              // 📌 المحتوى النصي
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // إذا فيه placeName نعرضه أولاً
                    if ((widget.placeName ?? "").isNotEmpty)
                      Text(
                        widget.placeName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),

                    // العنوان
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),

                    // الموقع والتصنيف
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.blueGrey[400]),
                        const SizedBox(width: 4),
                        Text(widget.city,
                            style: TextStyle(color: Colors.blueGrey[700])),
                        const SizedBox(width: 10),
                        Text(widget.category,
                            style: TextStyle(color: Colors.blueGrey[700])),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ⭐ التقييم النجمي
                    Stars(rating: widget.rating, size: 18),
                    const SizedBox(height: 4),
                    Text(
                      "(${widget.ratingCount} تقييم)",
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // 🔘 أزرار حسب الدور
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: widget.isAdmin
                    ? Row(
                  children: [
                    // زر تعديل
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("تعديل"),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditPlacePage(ref: widget.ref),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // زر حذف
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text("حذف"),
                        onPressed: () async {
                          await widget.ref.delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("تم الحذف بنجاح")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                )
                    : Row(
                  children: [
                    // المفضلة
                    FavoriteToggle(
                      isFav: widget.isFavorite,
                      onChanged: widget.onFavoriteChanged,
                      bgColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 10),
                    // تقييم
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.star_rate),
                        label: const Text("قيّم"),
                        onPressed: widget.onRate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // بلاغ
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flag),
                        label: const Text("بلاغ"),
                        onPressed: widget.onReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
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
