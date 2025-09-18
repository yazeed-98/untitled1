import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // 🟢 جديد
import 'dart:io';

import '../clasess/rating_sheet.dart' show RatingService;
import '../clasess/report_dialog.dart' show ReportService;
import 'PlaceDetailsPage.dart';

class OfferDetailsPage extends StatefulWidget {
  final Map<String, dynamic> offer;
  final bool isAdmin;

  const OfferDetailsPage({
    super.key,
    required this.offer,
    this.isAdmin = false,
  });

  @override
  State<OfferDetailsPage> createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  late Map<String, dynamic> offerData;

  @override
  void initState() {
    super.initState();
    offerData = Map<String, dynamic>.from(widget.offer);
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String id = offerData['id'];
    final ref = FirebaseFirestore.instance.collection('offers').doc(id);

    final String? placeId = offerData['placeId'];
    final String? placeType = offerData['placeType'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: Text(offerData['title'] ?? 'تفاصيل العرض'),
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
              if ((offerData['image'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    offerData['image'],
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),

              Text(
                offerData['title'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 🟢 اسم المكان قابل للنقر
              if (placeId != null && placeType != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(placeType)
                      .doc(placeId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Text(
                        "المكان: ${offerData['placeName'] ?? 'غير معروف'}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                        ),
                      );
                    }
                    final placeData =
                    snapshot.data!.data() as Map<String, dynamic>;
                    final name = placeData['name'] ?? offerData['placeName'];
                    final city = placeData['city'] ?? offerData['city'] ?? '';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailsPage(placeData: placeData),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.store, color: Colors.teal, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "المكان: $name ($city)",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 12),

              // 🟢 عرض رقم الهاتف إن وجد
              if ((offerData['phone'] ?? '').toString().isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.green, size: 20),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _makeCall(offerData['phone']),
                      child: Text(
                        offerData['phone'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              Text(
                offerData['description'] ?? 'لا يوجد وصف',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 🟢 باقي الأزرار مثل قيّم / إبلاغ / تعديل / حذف (نفس كودك السابق)
            ],
          ),
        ),
      ),
    );
  }

// 🔧 _showEditDialog نفسه تبعك (ما غيرته)
}
