import 'package:flutter/material.dart';

import '../clasess/app_snackbar.dart';
import 'RegisterStorePage.dart';
import 'RequestOfferPage.dart';

class AdOptionsPage extends StatelessWidget {
  const AdOptionsPage({super.key});

  void _showDisclaimer(BuildContext context, String type) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: colorScheme.secondary),
            const SizedBox(width: 8),
            const Text(
              "تنبيه مهم",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "عزيزي المعلن، نرجو العلم أن جميع المعلومات التي تقدمها "
              "يجب أن تكون صحيحة وحقيقية. وأنت تتحمل كامل المسؤولية "
              "عن أي خطأ أو معلومات غير صحيحة.\n\n"
              "بالضغط على موافق فأنت تؤكد التزامك بهذه الشروط.",
          textAlign: TextAlign.right,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            child: const Text('موافق'),
            onPressed: () {
              Navigator.pop(ctx); // اغلق التنبيه أولًا
              if (type == "ad") {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const NewOfferRequestPage()),
                );
              } else if (type == "store") {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const StoreRegistrationPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تقديم إعلان"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // زر إضافة إعلان
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("إضافة إعلان"),
                  onPressed: () => _showDisclaimer(context, "ad"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // زر تسجيل متجر جديد
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.store_mall_directory_outlined),
                  label: const Text("تسجيل متجر جديد"),
                  onPressed: () => _showDisclaimer(context, "store"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
