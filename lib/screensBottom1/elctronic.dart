// lib/screensBottom1/electronics_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart'            show PlaceCard;
import '../clasess/empty_state.dart'     show EmptyState;
import '../clasess/offers_section.dart';
import '../clasess/rating_sheet.dart'    show RatingService;
import '../clasess/report_dialog.dart'   show ReportResult, ReportService;
import '../clasess/SearchField.dart'     show SearchField;


class ElectronicsPage extends StatefulWidget {
  const ElectronicsPage({super.key, this.cityFilter, this.isAdmin = false});
  final String? cityFilter; // فلترة بالمحافظة (اختياري)
  final bool isAdmin;

  @override
  State<ElectronicsPage> createState() => _ElectronicsPageState();
}

class _ElectronicsPageState extends State<ElectronicsPage> {
  // بحث + فرز
  String _query = '';
  String _sort = 'top'; // top | cheap | name

  // فلاتر التصنيف
  String? _selectedCategory;
  final List<String> _categories = const [
    'هواتف',
    'حاسبات',
    'إلكترونيات منزلية',
    'ملحقات',
    'صيانة',
    'كاميرات',
    'ألعاب',
  ];

  // فلاتر إضافية
  bool _onlyWarranty = false;
  bool _onlyDelivery = false;
  bool _onlyInstallments = false;

  // مفضلات محليًا
  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('electronics');
    if ((widget.cityFilter ?? '').isNotEmpty) {
      return col.where('city', isEqualTo: widget.cityFilter).snapshots();
    }
    return col.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.cityFilter == null
        ? 'متاجر الإلكترونيات'
        : 'الإلكترونيات — ${widget.cityFilter}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontSize: 20)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'رجوع',
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
                hintText: 'ابحث باسم المتجر…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            // فلاتر التصنيف
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
                      label: const Text('كل التصنيفات'),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                    );
                  }
                  final c = _categories[i - 1];
                  return ChoiceChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    onSelected: (isSel) =>
                        setState(() => _selectedCategory = isSel ? c : null),
                  );
                },
              ),
            ),

            // فلاتر إضافية
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('كفالة'),
                      selected: _onlyWarranty,
                      onSelected: (v) => setState(() => _onlyWarranty = v),
                    ),
                    FilterChip(
                      label: const Text('توصيل'),
                      selected: _onlyDelivery,
                      onSelected: (v) => setState(() => _onlyDelivery = v),
                    ),
                    FilterChip(
                      label: const Text('تقسيط'),
                      selected: _onlyInstallments,
                      onSelected: (v) => setState(() => _onlyInstallments = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

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
                      icon: Icons.devices_other,
                      title: 'لا توجد بيانات',
                      subtitle: 'ابدأ بإضافة متاجر إلكترونيات من لوحة الإدارة.',
                    );
                  }

                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['id'] = d.id;
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  // فلترة
                  final filtered = list.where((m) {
                    final nameOk = (m['name'] ?? '').toString().contains(_query);
                    final cityOk =
                        widget.cityFilter == null || (m['city'] ?? '') == widget.cityFilter;
                    final catOk = _selectedCategory == null ||
                        (m['category'] ?? '') == _selectedCategory;

                    final warrOk = !_onlyWarranty || (m['warranty'] == true);
                    final delOk = !_onlyDelivery || (m['delivery'] == true);
                    final instOk = !_onlyInstallments || (m['installments'] == true);

                    return nameOk && cityOk && catOk && warrOk && delOk && instOk;
                  }).toList();

                  // فرز
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
                      icon: Icons.devices_other,
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
                        category: (h['type'] ?? '') as String,

                        imageUrl: (h['image'] ?? '') as String,
                        rating: avg,
                        ratingCount: (h['ratingCount'] as int?) ?? 0,
                        isFavorite: _favs.contains(id),
                        onFavoriteChanged: (v) => setState(() {
                          v ? _favs.add(id) : _favs.remove(id);
                        }),
                        ref: ref,
                        isAdmin: widget.isAdmin,
                        onRate: () => RatingService.rateRestaurant(
                          context,
                          ref: ref,
                          placeName: (h['name'] ?? '') as String,
                        ),
                        onReport: () => ReportService.reportPlace(
                          context,
                          placeType: 'electronics',
                          placeId: id,
                          placeName: (h['name'] ?? '') as String,
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

  double _avg(Map<String, dynamic> m) {
    final int count = (m['ratingCount'] as int?) ?? 0;
    final double sum = ((m['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }
}
