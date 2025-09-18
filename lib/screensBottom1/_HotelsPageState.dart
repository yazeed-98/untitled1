// lib/screensBottom1/hotels_page.dart
import 'package:flutter/material.dart';
import '../clasess/CategoryFilterWidget.dart';
import '../clasess/CustomAppBar.dart';
import '../clasess/offers_section.dart';
// ✅ المسار الصحيح

class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key, this.cityFilter, this.isAdmin = false});

  final String? cityFilter;
  final bool isAdmin;

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  String _sort = 'top';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.cityFilter == null
              ? 'الفنادق'
              : 'الفنادق — ${widget.cityFilter}',
          actions: [
            IconButton(
              tooltip: "العروض",
              icon: const Icon(
                Icons.local_offer_outlined,
                color: Colors.teal,
              ),
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
                PopupMenuItem(value: 'cheap', child: Text('الأقل تكلفة')),
                PopupMenuItem(value: 'name', child: Text('الاسم (أ-ي)')),
              ],
              icon: const Icon(
                Icons.sort,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        body: CategoryFilterWidget(
          collection: 'hotels',
          cityFilter: widget.cityFilter,
          isAdmin: widget.isAdmin,
          sortBy: _sort,
        ),
      ),
    );
  }
}
