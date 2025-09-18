// lib/screensBottom1/wholesale_page.dart
import 'package:flutter/material.dart';
import '../clasess/CustomAppBar.dart';
import '../clasess/offers_section.dart';
import '../clasess/CategoryFilterWidget.dart';

class WholesalePage extends StatefulWidget {
  const WholesalePage({super.key, this.cityFilter, this.isAdmin = false});

  final String? cityFilter;
  final bool isAdmin;

  @override
  State<WholesalePage> createState() => _WholesalePageState();
}

class _WholesalePageState extends State<WholesalePage> {
  String _sort = 'top';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.cityFilter == null
              ? 'محلات بيع الجملة'
              : 'الجملة — ${widget.cityFilter}',
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
                PopupMenuItem(value: 'cheap', child: Text('الأرخص')),
                PopupMenuItem(value: 'name', child: Text('الاسم (أ-ي)')),
              ],
              icon: const Icon(Icons.sort, color: Colors.blueGrey),
            ),
          ],
        ),
        body: CategoryFilterWidget(
          collection: 'wholesale',
          cityFilter: widget.cityFilter,
          isAdmin: widget.isAdmin,
          sortBy: _sort,
        ),
      ),
    );
  }
}
