// lib/screens/contracts_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl; // <- استيراد مع prefix

import 'only_sale_contract_page.dart';

class ContractsListPage extends StatelessWidget {
  const ContractsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('contracts')
        .orderBy('createdAt', descending: true);

    return Directionality(
      textDirection: TextDirection.rtl, // <- تأكد small-case "rtl"
      child: Scaffold(
        appBar: AppBar(title: const Text('عقودي')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('تعذّر تحميل العقود'));
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('لا توجد عقود بعد.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = docs[i];
                final m = d.data();

                final seller = (m['sellerName'] ?? '').toString();
                final buyer = (m['buyerName'] ?? '').toString();
                final title = seller.isNotEmpty && buyer.isNotEmpty
                    ? 'من $seller إلى $buyer'
                    : (m['title'] ?? 'عقد').toString();

                final type = (m['type'] ?? '-').toString();
                final city = (m['city'] ?? '-').toString();
                final price = (m['price'] ?? 0).toString();
                final currency = (m['currency'] ?? '').toString();
                final status = (m['status'] ?? '').toString();

                String? dateStr;
                if (m['createdAt'] != null && m['createdAt'] is Timestamp) {
                  final date = (m['createdAt'] as Timestamp).toDate();
                  dateStr = intl.DateFormat('yyyy/MM/dd – HH:mm').format(date);
                }

                return GestureDetector(
                  onLongPress: () => _showOptions(context, d.id, m),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: _buildLeadingPreview(m, context),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('النوع: $type • المدينة: $city'),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: -6,
                            children: [
                              Chip(
                                label: Text('السعر: $price'),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                              ),
                              if (currency.isNotEmpty)
                                Chip(
                                  label: Text('العملة: $currency'),
                                  backgroundColor: Colors.blue.shade50,
                                ),
                              if (status.isNotEmpty)
                                Chip(
                                  label: Text('الحالة: $status'),
                                  backgroundColor: Colors.green.shade50,
                                ),
                              if (dateStr != null)
                                Chip(
                                  label: Text('التاريخ: $dateStr'),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NameOnlySaleContractPage(contractId: d.id),
                          ),
                        );
                      },
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

  /// صورة مصغّرة أو أيقونة افتراضية
  Widget _buildLeadingPreview(Map<String, dynamic> m, BuildContext context) {
    final url = (m['previewUrl'] ?? '').toString().trim();
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(Icons.description_outlined,
            color: Theme.of(context).colorScheme.primary),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: 26,
          backgroundColor:
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  /// شيت الخيارات عند الضغط المطوّل
  void _showOptions(BuildContext context, String id, Map<String, dynamic> m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('عرض العقد'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NameOnlySaleContractPage(contractId: id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context);
                // TODO: افتح صفحة التعديل (نفس صفحة العقد لكن editable)
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف'),
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('contracts')
                    .doc(id)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العقد')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
