// lib/clasess/rating_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// شيت بسيط لاختيار تقييم نجوم.
/// استخدمه بأي صفحة مع عنوان مخصص.
class RatingSheet {
  static Future<double?> show(
      BuildContext context, {
        String title = 'قيّم المكان', // ← تقدر تغيّر العنوان حسب الصفحة
        double initial = 0,
        int starCount = 5,
        bool allowHalf = true,
        String cancelText = 'إلغاء',
        String submitText = 'إرسال',
      }) {
    double temp = initial;

    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              RatingBar.builder(
                initialRating: initial,
                minRating: 0,
                allowHalfRating: allowHalf,
                itemCount: starCount,
                itemSize: 36,
                itemPadding: const EdgeInsets.symmetric(horizontal: 3),
                itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (v) => temp = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(cancelText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(submitText),
                      onPressed: () => Navigator.pop(context, temp > 0 ? temp : null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// خدمة حفظ التقييم بشكل عام (مش بس للمطاعم)
class RatingService {
  /// يفتح شيت التقييم ثم يحدّث [sumField] و[countField] في مستند [ref] بترانزاكشن.
  /// ويحفظ سجلًا اختياريًا في Subcollection [detailSubcollection].
  static Future<void> ratePlace(
      BuildContext context, {
        required DocumentReference<Map<String, dynamic>> ref,
        String? placeName,                     // لرسالة الشكر فقط
        String sumField = 'ratingSum',         // اسم حقل مجموع التقييمات
        String countField = 'ratingCount',     // اسم حقل عدد المقيمين
        String detailSubcollection = 'ratings',// اسم الساب-كوليكشن الاختياري
        String sheetTitle = 'قيّم المكان',     // عنوان الشيت
      }) async {
    // 1) افتح شيت التقييم
    final value = await RatingSheet.show(context, title: sheetTitle);
    if (value == null) return;

    try {
      // 2) ترانزاكشن تحديث المجموع/العدد
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? {};
        final sum = (data[sumField] as num?)?.toDouble() ?? 0.0;
        final count = (data[countField] as int?) ?? 0;
        tx.update(ref, {
          sumField: sum + value,
          countField: count + 1,
        });
      });

      // 3) (اختياري) تخزين تفصيلي للتقييم
      try {
        await ref.collection(detailSubcollection).add({
          'value': value,
          'uid': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      // 4) رسالة نجاح
      if (context.mounted) {
        final namePart = (placeName == null || placeName.isEmpty) ? '' : ' لـ $placeName';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('شكراً! تم تسجيل تقييمك (${value.toStringAsFixed(1)})$namePart')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر حفظ التقييم: $e')),
        );
      }
    }
  }

  /// دالة مساعدة لحساب المتوسط من خريطة بيانات.
  static double avgFrom(Map<String, dynamic> data, {String sumField = 'ratingSum', String countField = 'ratingCount'}) {
    final int count = (data[countField] as int?) ?? 0;
    final double sum = ((data[sumField] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  static rateRestaurant(BuildContext context, {required DocumentReference<Map<String, dynamic>> ref, required String placeName}) {}
}
