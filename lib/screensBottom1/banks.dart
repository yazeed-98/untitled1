// lib/screensBottom1/finance_page.dart
import 'package:flutter/material.dart';
import '../clasess/CategoryFilterWidget.dart';
import '../clasess/CustomAppBar.dart';
import '../clasess/offers_section.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key, this.cityFilter, this.isAdmin = false});
  final String? cityFilter;
  final bool isAdmin;

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  String _sort = 'top'; // 👈 نفس اللي عملناه بالفنادق

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.cityFilter == null
              ? 'البنوك والتمويل'
              : 'البنوك والتمويل — ${widget.cityFilter}',
          actions: [
            IconButton(
              tooltip: "العروض",
              icon: const Icon(Icons.local_offer_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OffersPage()),
                );
              },
            ),
            PopupMenuButton<String>(
              tooltip: 'فرز',
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'top', child: Text('الأعلى تقييمًا')),
                PopupMenuItem(value: 'cheap', child: Text('الأقل رسومًا')),
                PopupMenuItem(value: 'name', child: Text('الاسم (أ-ي)')),
              ],
              icon: const Icon(Icons.sort, color: Colors.blueGrey),
            ),
          ],
        ),
        body: CategoryFilterWidget(
          collection: 'finance_providers',
          cityFilter: widget.cityFilter,
          isAdmin: widget.isAdmin,
          // 👇 مرر خيار الفرز للودجت
          sortBy: _sort,
        ),
      ),
    );
  }
}
