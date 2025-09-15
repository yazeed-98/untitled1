import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/app_snackbar.dart';

class AdminRequestsPage extends StatelessWidget {
  const AdminRequestsPage({super.key});

  Future<bool> approveRequest(BuildContext context, DocumentSnapshot request) async {
    final data = request.data() as Map<String, dynamic>;

    if (data["collection"] == null) {
      AppSnackBar.show(
        context,
        "خطأ: لم يتم تحديد القسم",
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.error,
      );
      return false;
    }

    final String targetCollection = data["collection"];

    try {
      await FirebaseFirestore.instance.collection(targetCollection).add({
        "name": data["name"],
        "description": data["description"],
        "approved": true,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await request.reference.delete();

      AppSnackBar.show(
        context,
        "تمت الموافقة على الطلب",
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icons.check_circle,
      );
      return true;
    } catch (e) {
      AppSnackBar.show(
        context,
        "حدث خطأ أثناء الموافقة",
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.error,
      );
      return false;
    }
  }

  Future<bool> rejectRequest(BuildContext context, DocumentSnapshot request) async {
    try {
      await request.reference.delete();
      AppSnackBar.show(
        context,
        "تم رفض الطلب",
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.cancel,
      );
      return true;
    } catch (e) {
      AppSnackBar.show(
        context,
        "حدث خطأ أثناء الرفض",
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
          title: const Text("طلبات بانتظار الموافقة"),
          // يقرأ من الثيم
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("requests")
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
                  "لا يوجد طلبات جديدة",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final data = request.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      data["name"] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      data["description"] ?? "",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "قبول",
                          icon: Icon(Icons.check, color: colorScheme.primary),
                          onPressed: () => approveRequest(context, request),
                        ),
                        IconButton(
                          tooltip: "رفض",
                          icon: Icon(Icons.close, color: colorScheme.error),
                          onPressed: () => rejectRequest(context, request),
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
