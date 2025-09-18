// lib/screensBottom1/restaurants_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Widgets / Classes خارجية
import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart'             show PlaceCard;
import '../clasess/empty_state.dart'     show EmptyState;
import '../clasess/offers_section.dart';
import '../clasess/rating_sheet.dart'    show RatingService;
import '../clasess/SearchField.dart'     show SearchField;
import '../clasess/report_dialog.dart';
import '../clasess/report_service.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key, this.cityFilter, this.isAdmin = false});
  final String? cityFilter;
  final bool isAdmin;

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  String _query = '';
  String _sort = 'top'; // top | cheap | name
  String? _selectedCuisine;
  final List<String> _cuisines = const ['أردني', 'مشاوي', 'إيطالي', 'ياباني', 'سناك'];

  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('restaurants');
    if ((widget.cityFilter ?? '').isNotEmpty) {
      return col.where('city', isEqualTo: widget.cityFilter).snapshots();
    }
    return col.snapshots();
  }

  double _avg(Map<String, dynamic> r) {
    final int count = (r['ratingCount'] as int?) ?? 0;
    final double sum = ((r['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  IconData _iconForCuisine(String c) {
    switch (c) {
      case 'أردني':
        return Icons.restaurant;
      case 'مشاوي':
        return Icons.outdoor_grill;
      case 'إيطالي':
        return Icons.local_pizza;
      case 'ياباني':
        return Icons.rice_bowl;
      case 'سناك':
        return Icons.fastfood;
      default:
        return Icons.restaurant_menu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.cityFilter == null
        ? 'المطاعم'
        : 'مطاعم ${widget.cityFilter}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
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
              icon: const Icon(Icons.sort),
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                hintText: 'ابحث باسم المطعم…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            // Dropdown الفلتر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'اختر نوع المطبخ',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCuisine,
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  ..._cuisines.map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(_iconForCuisine(c), size: 20),
                        const SizedBox(width: 8),
                        Text(c),
                      ],
                    ),
                  )),
                ],
                onChanged: (v) => setState(() => _selectedCuisine = v),
              ),
            ),
            const SizedBox(height: 8),

            // البيانات
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const EmptyState(
                      icon: Icons.error_outline,
                      title: 'تعذّر تحميل البيانات',
                      subtitle: 'تحقق من الاتصال أو صلاحيات Firestore.',
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'لا توجد نتائج مطابقة',
                      subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                    );
                  }

                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['id'] = d.id;
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  final filtered = list.where((r) {
                    final nameOk = (r['name'] ?? '').toString().contains(_query);
                    final cuisineOk = _selectedCuisine == null || r['cuisine'] == _selectedCuisine;
                    final cityOk = widget.cityFilter == null || (r['city'] ?? '') == widget.cityFilter;
                    return nameOk && cuisineOk && cityOk;
                  }).toList();

                  filtered.sort((a, b) {
                    switch (_sort) {
                      case 'cheap':
                        final ap = (a['price'] as num?) ?? 1;
                        final bp = (b['price'] as num?) ?? 1;
                        return ap.compareTo(bp);
                      case 'name':
                        return ((a['name'] ?? '') as String)
                            .compareTo((b['name'] ?? '') as String);
                      case 'top':
                      default:
                        return _avg(b).compareTo(_avg(a));
                    }
                  });

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'لا توجد نتائج مطابقة',
                      subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final r = filtered[i];
                      final avg = _avg(r);
                      final id = r['id'] as String;
                      final ref = r['ref'] as DocumentReference<Map<String, dynamic>>;

                      return PlaceCard(
                        title: (r['name'] ?? '') as String,
                        city: (r['city'] ?? '') as String,
                        category: (r['type'] ?? '') as String,
                        imageUrl: (r['image'] ?? '') as String,
                        rating: avg,
                        ratingCount: (r['ratingCount'] as int?) ?? 0,
                        isFavorite: _favs.contains(id),
                        onFavoriteChanged: (v) => setState(() {
                          v ? _favs.add(id) : _favs.remove(id);
                        }),
                        ref: ref,
                        isAdmin: widget.isAdmin,
                        onRate: () => RatingService.rateRestaurant(
                          context,
                          ref: ref,
                          placeName: (r['name'] ?? '') as String,
                        ),
                        onReport: () => ReportService.reportPlace(
                          context,
                          placeType: 'restaurant',
                          placeId: id,
                          placeName: (r['name'] ?? '') as String,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailsPage(placeData: r),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
