import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'report_dialog.dart';

class ReportService {
  static Future<void> reportPlace(
      BuildContext context, {
        required String placeType,  // ex: restaurants
        required String placeId,
        required String placeName,
      }) async {
    final res = await ReportDialog.show(context, placeName: placeName);
    if (res == null) return;

    try {
      // 🟢 إضافة البلاغ
      await FirebaseFirestore.instance.collection('reports').add({
        'placeType': placeType,
        'placeId': placeId,
        'placeName': placeName,
        'type': res.type,
        'details': res.details ?? '',
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔍 عدّ عدد البلاغات الفريدة
      final reports = await FirebaseFirestore.instance
          .collection('reports')
          .where('placeId', isEqualTo: placeId)
          .where('placeType', isEqualTo: placeType)
          .get();

      final uniqueUsers = reports.docs.map((d) => d['uid']).toSet();

      if (uniqueUsers.length >= 5) {
        // 👀 إخفاء الإعلان مؤقتاً
        await FirebaseFirestore.instance
            .collection(placeType)
            .doc(placeId)
            .update({'isHidden': true});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🚨 الإعلان تم الإبلاغ عنه أكثر من 5 مرات وتم إخفاؤه للمراجعة')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال البلاغ، شكرًا لتنبيهك 🙏')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر إرسال البلاغ: $e')),
        );
      }
    }
  }
}
