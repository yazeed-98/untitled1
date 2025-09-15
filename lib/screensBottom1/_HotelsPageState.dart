// lib/screensBottom1/hotels_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Widgets / Classes خارجية
import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart'            show PlaceCard;
import '../clasess/empty_state.dart'     show EmptyState;
import '../clasess/offers_section.dart';
import '../clasess/rating_sheet.dart'    show RatingService;
import '../clasess/report_dialog.dart'   show ReportService;
import '../clasess/SearchField.dart'     show SearchField;

class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key, this.cityFilter, this.isAdmin = false});
  final String? cityFilter;
  final bool isAdmin;

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  String _query = '';
  String _sort = 'top'; // top | cheap | name
  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('hotels');
    if ((widget.cityFilter ?? '').isNotEmpty) {
      return col.where('city', isEqualTo: widget.cityFilter).snapshots();
    }
    return col.snapshots();
  }

  double _avg(Map<String, dynamic> m) {
    final count = (m['ratingCount'] as int?) ?? 0;
    final sum = ((m['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final title = widget.cityFilter == null
        ? 'الفنادق'
        : 'الفنادق — ${widget.cityFilter}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: Text(title, style: TextStyle(color: Colors.blueGrey[900])),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
          elevation: 0,
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
                PopupMenuItem(value: 'cheap', child: Text('الأقل تكلفة')),
                PopupMenuItem(value: 'name', child: Text('الاسم (أ-ي)')),
              ],
              icon: const Icon(Icons.sort, color: Colors.blueGrey),
            ),
          ],
        ),

        body: Column(
          children: [
            // ✅ شريط البحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                hintText: 'ابحث باسم الفندق…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            const SizedBox(height: 4),

            // ✅ البيانات
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
                      icon: Icons.hotel,
                      title: 'لا توجد بيانات',
                      subtitle: 'ابدأ بإضافة فنادق من لوحة الإدارة.',
                    );
                  }

                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['id'] = d.id;
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  final filtered = list.where((m) {
                    final nameOk = (m['name'] ?? '').toString().contains(_query);
                    final cityOk = widget.cityFilter == null ||
                        (m['city'] ?? '') == widget.cityFilter;
                    return nameOk && cityOk;
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
                        final ar = _avg(a);
                        final br = _avg(b);
                        return br.compareTo(ar);
                    }
                  });

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.hotel,
                      title: 'لا توجد نتائج مطابقة',
                      subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final h = filtered[i];
                      final avg = _avg(h);
                      final id = h['id'] as String;
                      final ref = h['ref'] as DocumentReference<Map<String, dynamic>>;

                      return PlaceCard(
                        title: (h['name'] ?? '') as String,
                        city: (h['city'] ?? '') as String,
                        category: (h['category'] ?? 'فندق') as String,

                        imageUrl: (h['image'] ?? '') as String,
                        rating: avg,
                        ratingCount: (h['ratingCount'] as int?) ?? 0,
                        isFavorite: _favs.contains(id),
                        onFavoriteChanged: (v) => setState(() {
                          v ? _favs.add(id) : _favs.remove(id);
                        }),
                        ref: ref,
                        isAdmin: widget.isAdmin,

                        // ✅ تقييم
                        onRate: () => RatingService.rateRestaurant(
                          context,
                          ref: ref,
                          placeName: (h['name'] ?? '') as String,
                        ),

                        // ✅ إبلاغ
                        onReport: () => ReportService.reportPlace(
                          context,
                          placeType: 'hotel',
                          placeId: id,
                          placeName: (h['name'] ?? '') as String,
                        ),

                        // ✅ تفاصيل الفندق
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                              builder: (_) => PlaceDetailsPage(placeData: h),


                          ));},
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
