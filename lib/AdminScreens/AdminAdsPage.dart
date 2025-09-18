import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRequestsPage extends StatelessWidget {
  const AdminRequestsPage({super.key});

  Future<void> _approveRequest(DocumentSnapshot request) async {
    final data = request.data() as Map<String, dynamic>;
    final collectionName = data["collection"]; // الكولكشن المستهدف (restaurants, hotels...)

    if (collectionName == null) return;

    // أضف البيانات للكولكشن المناسب
    await FirebaseFirestore.instance.collection(collectionName).add({
      "name": data["name"],
      "description": data["description"],
      "phone": data["phone"],
      "imageUrl": data["imageUrl"],
      "city": data["city"] ?? '',
      "location": data["location"] ?? '',
      "category": data["subCategory"] ?? '',
      "ratingCount": 0,
      "ratingSum": 0,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // احذف الطلب من requests
    await request.reference.delete();
  }

  Future<void> _rejectRequest(DocumentSnapshot request) async {
    // مجرد حذف الطلب من requests
    await request.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إدارة الطلبات"),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("requests")
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("حدث خطأ أثناء تحميل الطلبات"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text("لا توجد طلبات حالياً"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data["name"] ?? "بدون اسم",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("القسم: ${data["collection"] ?? "-"}"),
                        if ((data["subCategory"] ?? '').isNotEmpty)
                          Text("التصنيف: ${data["subCategory"]}"),
                        if ((data["city"] ?? '').isNotEmpty)
                          Text("المحافظة: ${data["city"]}"),
                        const SizedBox(height: 8),
                        Text(data["description"] ?? ""),
                        const SizedBox(height: 12),

                        // أزرار الموافقة / الرفض
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveRequest(doc),
                                icon: const Icon(Icons.check),
                                label: const Text("موافقة"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _rejectRequest(doc),
                                icon: const Icon(Icons.close),
                                label: const Text("رفض"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
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
