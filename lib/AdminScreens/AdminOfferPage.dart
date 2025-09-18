import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/app_snackbar.dart';

class AdminOfferRequestsPage extends StatelessWidget {
  const AdminOfferRequestsPage({super.key});

  /// ✅ الموافقة على طلب عرض
  Future<bool> approveRequest(BuildContext context, DocumentSnapshot request) async {
    final data = request.data() as Map<String, dynamic>;
    try {
      final placeId = data["placeId"];
      final placeType = data["placeType"];

      if (placeId != null && placeType != null) {
        // 🔹 إضافة العرض داخل المكان نفسه (مثلاً: restaurants/{placeId}/offers)
        await FirebaseFirestore.instance
            .collection(placeType)
            .doc(placeId)
            .collection("offers")
            .add({
          "title": data["title"],
          "description": data["description"] ?? '',
          "placeName": data["placeName"] ?? '',
          "city": data["city"] ?? '',
          "image": data["image"] ?? '',
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      // 🔹 إضافة نسخة عامة في كولكشن العروض
      await FirebaseFirestore.instance.collection("offers").add({
        "title": data["title"],
        "description": data["description"] ?? '',
        "placeName": data["placeName"] ?? '',
        "city": data["city"] ?? '',
        "image": data["image"] ?? '',
        "placeId": data["placeId"],
        "placeType": data["placeType"],
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 🗑️ حذف الطلب بعد الموافقة
      await request.reference.delete();

      AppSnackBar.show(
        context,
        "تمت الموافقة على العرض ✅",
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icons.check_circle,
      );
      return true;
    } catch (e) {
      AppSnackBar.show(
        context,
        "حدث خطأ أثناء الموافقة: $e",
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.error,
      );
      return false;
    }
  }

  /// ❌ رفض الطلب
  Future<bool> rejectRequest(BuildContext context, DocumentSnapshot request) async {
    try {
      await request.reference.delete();
      AppSnackBar.show(
        context,
        "تم رفض الطلب ❌",
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.cancel,
      );
      return true;
    } catch (e) {
      AppSnackBar.show(
        context,
        "حدث خطأ أثناء الرفض: $e",
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.error,
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("طلبات العروض"),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("offerRequests")
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data!.docs;
            if (requests.isEmpty) {
              return const Center(
                child: Text(
                  "لا توجد طلبات جديدة",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final data = request.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🖼️ صورة العرض
                        if ((data["image"] ?? '').isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              data["image"],
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 10),

                        // 📝 العنوان
                        Text(
                          data["title"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 📍 المكان
                        if ((data["placeName"] ?? '').isNotEmpty)
                          Text(
                            "📍 ${data["placeName"]}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey[700],
                            ),
                          ),

                        // 📄 الوصف
                        if ((data["description"] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              data["description"],
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // ✅❌ أزرار الموافقة والرفض
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: "قبول",
                              icon: Icon(Icons.check_circle,
                                  color: colorScheme.primary),
                              onPressed: () => approveRequest(context, request),
                            ),
                            IconButton(
                              tooltip: "رفض",
                              icon: Icon(Icons.cancel,
                                  color: colorScheme.error),
                              onPressed: () => rejectRequest(context, request),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
