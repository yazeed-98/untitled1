import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'offers_section.dart';



class PlaceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> placeData;
  final bool isAdmin;

  const PlaceDetailsPage({
    super.key,
    required this.placeData,
    this.isAdmin = false,
  });

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  bool _isFavorite = false;

  double get avgRating {
    final int count = (widget.placeData['ratingCount'] as int?) ?? 0;
    final double sum =
        ((widget.placeData['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  /// 🟢 فتح الموقع
  Future<void> _openMap() async {
    final city = widget.placeData['city'] ?? '';
    final location = widget.placeData['location'] ?? '';

    if (city.isEmpty && location.isEmpty) return;

    final query = Uri.encodeComponent("$city $location");
    final url = "https://www.google.com/maps/search/?api=1&query=$query";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ ما قدرت أفتح الرابط: $url");
    }
  }

  /// 🟢 الاتصال برقم الهاتف
  Future<void> _makeCall() async {
    final phone = widget.placeData['phone'] ?? '';
    if (phone.isEmpty) return;

    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        appBar: AppBar(
          title: Text(widget.placeData['name'] ?? 'تفاصيل المكان'),
          backgroundColor: theme.primaryColor,
          foregroundColor: theme.colorScheme.onPrimary,
          centerTitle: true,
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // 🖼️ صورة المكان
            if ((widget.placeData['image'] ?? '').toString().isNotEmpty)
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Image.network(
                  widget.placeData['image'],
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📌 الاسم
                  Text(
                    widget.placeData['name'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColorDark,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 📍 المدينة + النوع
                  Row(
                    children: [
                      if ((widget.placeData['city'] ?? '').isNotEmpty) ...[
                        const Icon(Icons.location_on,
                            size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          widget.placeData['city'],
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if ((widget.placeData['category'] ?? '').isNotEmpty) ...[
                        const Icon(Icons.category,
                            size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          widget.placeData['category'],
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ⭐ التقييم
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 22),
                      const SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${(widget.placeData['ratingCount'] as int?) ?? 0} تقييم)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 📝 الوصف
                  if ((widget.placeData['description'] ?? '')
                      .toString()
                      .isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الوصف',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.placeData['description'],
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // 📍📞 أزرار
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on),
                          label: const Text("الموقع"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _openMap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.phone),
                          label: const Text("الاتصال"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _makeCall,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🟢 زر العروض
                  if (!widget.isAdmin)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.local_offer),
                      label: const Text("قائمة العروض"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OffersPage(
                              isAdmin: false,
                              // تمرير فلترة العروض
                              filterPlaceId: widget.placeData['id'],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // ❤️ المفضلة
                  if (!widget.isAdmin)
                    Center(
                      child: IconButton(
                        icon: Icon(
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 34,
                        ),
                        onPressed: () =>
                            setState(() => _isFavorite = !_isFavorite),
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
