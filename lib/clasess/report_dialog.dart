import 'package:flutter/material.dart';

class ReportResult {
  final String type;
  final String? details;
  const ReportResult({required this.type, this.details});
}

class ReportDialog {
  static Future<ReportResult?> show(BuildContext context, {String? placeName}) {
    final issues = [
      'معلومات خاطئة',
      'صور غير مناسبة',
      'مغلق/غير موجود',
      'سلوك غير لائق',
      'شيء آخر',
    ];
    String? selected = issues.first;
    final controller = TextEditingController();

    return showDialog<ReportResult>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(placeName == null ? 'إرسال بلاغ' : 'الإبلاغ عن: $placeName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selected,
                decoration: const InputDecoration(
                  labelText: 'نوع البلاغ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => selected = v,
                items: issues.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل إضافية (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton.icon(
              icon: const Icon(Icons.flag),
              label: const Text('إرسال البلاغ'),
              onPressed: () {
                if (selected == null) return;
                final txt = controller.text.trim();
                Navigator.pop(context, ReportResult(type: selected!, details: txt.isEmpty ? null : txt));
              },
            ),
          ],
        ),
      ),
    );
  }
}
