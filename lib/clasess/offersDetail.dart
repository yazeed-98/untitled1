import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// خدمات خارجيّة
import '../clasess/rating_sheet.dart' show RatingService;
import '../clasess/report_dialog.dart' show ReportService;

class OfferDetailsPage extends StatelessWidget {
  final Map<String, dynamic> offer;

  const OfferDetailsPage({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final String id = offer['id'];
    final ref = FirebaseFirestore.instance.collection('offers').doc(id);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: Text(offer['title'] ?? 'تفاصيل العرض'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ صورة العرض
              if ((offer['image'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    offer['image'],
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 16),

              // 📌 العنوان
              Text(
                offer['title'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // 📍 المدينة ونوع المكان
              if ((offer['city'] ?? '').toString().isNotEmpty)
                Text(
                  "المكان: ${offer['city']} (${offer['placeType'] ?? ''})",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),

              const SizedBox(height: 12),

              // 📝 الوصف
              Text(
                offer['description'] ?? 'لا يوجد وصف',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // ⭐ أزرار التقييم والإبلاغ
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      RatingService.rateRestaurant(
                        context,
                        ref: ref,
                        placeName: offer['title'] ?? 'عرض',
                      );
                    },
                    icon: const Icon(Icons.star_rate, color: Colors.white),
                    label: const Text("قيّم العرض"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ReportService.reportPlace(
                        context,
                        placeType: 'offer',
                        placeId: id,
                        placeName: offer['title'] ?? 'عرض',
                      );
                    },
                    icon: const Icon(Icons.report, color: Colors.white),
                    label: const Text("إبلاغ"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
