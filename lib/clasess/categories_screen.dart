import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriesScreen extends StatelessWidget {
  final String governorate;

  const CategoriesScreen({super.key, required this.governorate});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text("المتاجر في $governorate"),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("stores") // 👈 غيرها حسب الكولكشن
              .where("city", isEqualTo: governorate)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("حدث خطأ أثناء تحميل البيانات"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  "لا توجد متاجر في $governorate حالياً",
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    title: Text(data['name'] ?? "بدون اسم"),
                    subtitle: Text(data['description'] ?? "بدون وصف"),
                    leading: data['imageUrl'] != null &&
                        (data['imageUrl'] as String).isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['imageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(Icons.store, size: 40),
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
