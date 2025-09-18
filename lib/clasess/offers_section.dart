import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled1/clasess/report_service.dart';

import '../clasess/rating_sheet.dart' show RatingService;
import '../clasess/report_dialog.dart' show ReportService;
import 'PlaceDetailsPage.dart';
import 'offersDetail.dart';

class OffersPage extends StatelessWidget {
  final bool isAdmin;
  final String? filterPlaceId; // ✅ باراميتر جديد للفلترة

  const OffersPage({
    super.key,
    this.isAdmin = false,
    this.filterPlaceId,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ إذا في فلترة
    final query = filterPlaceId != null
        ? FirebaseFirestore.instance
        .collection('offers')
        .where('placeId', isEqualTo: filterPlaceId)
        .orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
        .collection('offers')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("العروض"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ أثناء تحميل العروض"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("لا يوجد عروض حالياً"));
          }

          final offers = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            data['ref'] = d.reference;
            return data;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, i) {
              final o = offers[i];
              final id = o['id'] as String;
              final ref = o['ref'] as DocumentReference<Map<String, dynamic>>;

              // معدل التقييم
              final ratings = (o['ratings'] as Map?) ?? {};
              final avg = ratings.isEmpty
                  ? 0.0
                  : ratings.values
                  .map((e) => (e as num).toDouble())
                  .reduce((a, b) => a + b) /
                  ratings.length;

              return OfferCard(
                offer: o,
                rating: avg,
                isAdmin: isAdmin,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfferDetailsPage(
                        offer: o,
                        isAdmin: isAdmin,
                      ),
                    ),
                  );
                },
                onRate: () => RatingService.ratePlace(
                  context,
                  ref: ref,
                  placeName: (o['title'] ?? '') as String,
                ),
                onReport: () => ReportService.reportPlace(
                  context,
                  placeType: 'offer',
                  placeId: id,
                  placeName: (o['title'] ?? '') as String,
                ),
                onDelete: () async {
                  await ref.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حذف العرض بنجاح")),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final double rating;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onRate;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  const OfferCard({
    super.key,
    required this.offer,
    required this.rating,
    required this.isAdmin,
    required this.onTap,
    required this.onRate,
    required this.onReport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final placeId = offer['placeId'];
    final placeType = offer['placeType'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 اسم المكان قابل للنقر
              if (placeId != null && placeType != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(placeType)
                      .doc(placeId)
                      .get(),
                  builder: (context, snapshot) {
                    String placeName = offer['placeName'] ?? 'غير معروف';

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final placeData =
                      snapshot.data!.data() as Map<String, dynamic>;
                      placeName = placeData['name'] ?? placeName;
                    }

                    return GestureDetector(
                      onTap: () {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final placeData =
                          snapshot.data!.data() as Map<String, dynamic>;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailsPage(
                                placeData: {
                                  ...placeData,
                                  "id": placeId,
                                  "type": placeType,
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "📍 $placeName",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 8),

              if ((offer['image'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    offer['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                offer['title'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // ⭐ التقييم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1)),
                    ],
                  ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                ],
              ),

              // ✅ المستخدم العادي فقط
              if (!isAdmin)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star_rate),
                      label: const Text("قيّم"),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: onReport,
                      icon: const Icon(Icons.report),
                      label: const Text("إبلاغ"),
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
