// lib/screensBottom1/clothing_shops_page.dart
import 'package:flutter/material.dart';
import '../clasess/CategoryFilterWidget.dart';
import '../clasess/CustomAppBar.dart';
import '../clasess/offers_section.dart';

class ClothingShopsPage extends StatefulWidget {
  const ClothingShopsPage({super.key, this.cityFilter, this.isAdmin = false});
  final String? cityFilter;
  final bool isAdmin;

  @override
  State<ClothingShopsPage> createState() => _ClothingShopsPageState();
}

class _ClothingShopsPageState extends State<ClothingShopsPage> {
  String _sort = 'top';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.cityFilter == null
              ? 'محلات الملابس'
              : 'محلات الملابس — ${widget.cityFilter}',
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
                PopupMenuItem(value: 'cheap', child: Text('الأقل تكلفة')),
                PopupMenuItem(value: 'name', child: Text('الاسم (أ-ي)')),
              ],
              icon: const Icon(Icons.sort, color: Colors.blueGrey),
            ),
          ],
        ),
        body: CategoryFilterWidget(
          collection: 'clothing_shops',
          cityFilter: widget.cityFilter,
          isAdmin: widget.isAdmin,
          sortBy: _sort,
        ),
      ),
    );
  }
}
