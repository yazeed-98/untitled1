import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../clasess/rating_sheet.dart';
import '../clasess/report_dialog.dart';

class PlaceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> placeData;

  const PlaceDetailsPage({super.key, required this.placeData});

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  bool _isFavorite = false;

  double get avgRating {
    final int count = (widget.placeData['ratingCount'] as int?) ?? 0;
    final double sum = ((widget.placeData['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DocumentReference<Map<String, dynamic>>? ref =
    widget.placeData['ref'] as DocumentReference<Map<String, dynamic>>?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.placeData['name'] ?? 'تفاصيل المكان'),
          backgroundColor: theme.primaryColor,
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // صورة المكان مع زوايا مدورة
            if ((widget.placeData['image'] ?? '').toString().isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Image.network(
                  widget.placeData['image'],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم
                  Text(
                    widget.placeData['name'] ?? '',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColorDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // المدينة + النوع
                  Row(
                    children: [
                      if ((widget.placeData['city'] ?? '').isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              widget.placeData['city'],
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      if ((widget.placeData['type'] ?? '').isNotEmpty)
                        Text(
                          widget.placeData['type'],
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // التقييم
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${(widget.placeData['ratingCount'] as int?) ?? 0} تقييم)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // الوصف
                  if ((widget.placeData['description'] ?? '').toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوصف',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColorDark),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.placeData['description']),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // أزرار التفاعل
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.star_rate),
                          label: const Text("قيّم"),
                          onPressed: ref != null
                              ? () => RatingService.ratePlace(
                            context,
                            ref: ref,
                            placeName: widget.placeData['name'] ?? '',
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flag),
                          label: const Text("بلاغ"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => ReportService.reportPlace(
                            context,
                            placeType: widget.placeData['type'] ?? 'place',
                            placeId: widget.placeData['id'] ?? '',
                            placeName: widget.placeData['name'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // زر المفضلة
                  Center(
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
