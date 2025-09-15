import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart'            show PlaceCard;
import '../clasess/empty_state.dart'     show EmptyState;
import '../clasess/SearchField.dart'     show SearchField;
import '../clasess/offers_section.dart';
import '../clasess/rating_sheet.dart'    show RatingService;
import '../clasess/report_dialog.dart'   show ReportService;


class ClothingShopsPage extends StatefulWidget {
  const ClothingShopsPage({super.key, this.cityFilter,  this.isAdmin=false});
  final String? cityFilter;
  final bool isAdmin;
  @override
  State<ClothingShopsPage> createState() => _ClothingShopsPageState();
}

class _ClothingShopsPageState extends State<ClothingShopsPage> {
  String _query = '';
  String _sort  = 'top';
  String? _selectedCategory;

  final List<String> _categories = const ['رجالي', 'نسائي', 'أطفال', 'أحذية', 'اكسسوارات'];
  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('clothing_shops');
    if ((widget.cityFilter ?? '').isNotEmpty) {
      return col.where('city', isEqualTo: widget.cityFilter).snapshots();
    }
    return col.snapshots();
  }

  double _avg(Map<String, dynamic> m) {
    final int count  = (m['ratingCount'] as int?) ?? 0;
    final double sum = ((m['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.cityFilter == null ? 'محلات الملابس' : 'محلات الملابس - ${widget.cityFilter}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
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
            // بحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                hintText: 'ابحث باسم المحل…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            // فلتر الفئة
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final sel = _selectedCategory == null;
                    return ChoiceChip(
                      label: const Text('الكل'),
                      selected: sel,
                      selectedColor: theme.primaryColor,
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.blueGrey[900],
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                    );
                  }
                  final c = _categories[i - 1];
                  final sel = _selectedCategory == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: sel,
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.blueGrey[900],
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                  );
                },
              ),
            ),

            // البيانات
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream(),
                builder: (context, snap) {
                  if (snap.hasError) return const EmptyState(
                    icon: Icons.error_outline,
                    title: 'تعذّر تحميل البيانات',
                    subtitle: 'تحقق من الاتصال أو صلاحيات Firestore.',
                  );
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) return const EmptyState(
                    icon: Icons.shopping_bag,
                    title: 'لا توجد بيانات',
                    subtitle: 'ابدأ بإضافة بيانات من لوحة الإدارة.',
                  );

                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  final filtered = list.where((s) {
                    final nameOk = (s['name'] ?? '').toString().contains(_query);
                    final catOk  = _selectedCategory == null || s['category'] == _selectedCategory;
                    final cityOk = widget.cityFilter == null || (s['city'] ?? '') == widget.cityFilter;
                    return nameOk && catOk && cityOk;
                  }).toList();

                  filtered.sort((a, b) {
                    switch (_sort) {
                      case 'cheap':
                        final ap = (a['price'] as num?) ?? 1;
                        final bp = (b['price'] as num?) ?? 1;
                        return ap.compareTo(bp);
                      case 'name':
                        return ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String);
                      case 'top':
                      default:
                        final ar = _avg(a);
                        final br = _avg(b);
                        return br.compareTo(ar);
                    }
                  });

                  if (filtered.isEmpty) return const EmptyState(
                    icon: Icons.shopping_bag,
                    title: 'لا توجد نتائج مطابقة',
                    subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final h = filtered[i];
                      final avg = _avg(h);

                      return PlaceCard(
                        title: h['name'] ?? '',
                        city: h['city'] ?? '',
                        category: h['category'] ?? '',

                        imageUrl: h['image'] ?? '',
                        rating: avg,
                        ratingCount: (h['ratingCount'] as int?) ?? 0,
                        isFavorite: _favs.contains(h['ref'].id),
                        onFavoriteChanged: (v) => setState(() {
                          v ? _favs.add(h['ref'].id) : _favs.remove(h['ref'].id);
                        }),
                        ref: h['ref'],
                        isAdmin: widget.isAdmin,
                        onRate: () => RatingService.ratePlace(
                          context,
                          ref: h['ref'],
                          placeName: h['name'] ?? '',
                        ),
                        onReport: () => ReportService.reportPlace(
                          context,
                          placeType: 'clothing',
                          placeId: h['ref'].id,
                          placeName: h['name'] ?? '',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailsPage(placeData: h),
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
