import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart'            show PlaceCard;
import '../clasess/empty_state.dart'     show EmptyState;
import '../clasess/offers_section.dart';
import '../clasess/rating_sheet.dart'    show RatingService;
import '../clasess/report_dialog.dart'   show ReportService;
import '../clasess/SearchField.dart'     show SearchField;


class CarsPage extends StatefulWidget {
  const CarsPage({super.key, this.cityFilter,  this.isAdmin=false});
  final String? cityFilter;
  final bool isAdmin;
  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  String _query = '';
  String _sort  = 'top';
  String? _selectedKind;

  final List<String> _kinds = const ['معرض', 'قطع', 'صيانة', 'زينة'];
  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('cars');
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
    final title = widget.cityFilter == null ? 'السيارات' : 'السيارات — ${widget.cityFilter}';

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
                hintText: 'ابحث باسم المعرض/المحل…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            // فلتر النوع
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _kinds.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final sel = _selectedKind == null;
                    return ChoiceChip(
                      label: const Text('كل الأنواع'),
                      selected: sel,
                      selectedColor: theme.primaryColor,
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.blueGrey[900],
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (_) => setState(() => _selectedKind = null),
                    );
                  }
                  final k = _kinds[i - 1];
                  final sel = _selectedKind == k;
                  return ChoiceChip(
                    label: Text(k),
                    selected: sel,
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.blueGrey[900],
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (_) => setState(() => _selectedKind = k),
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
                    icon: Icons.directions_car,
                    title: 'لا توجد بيانات',
                    subtitle: 'ابدأ بإضافة بيانات من لوحة الإدارة.',
                  );

                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  final filtered = list.where((m) {
                    final nameOk = (m['name'] ?? '').toString().contains(_query);
                    final kindOk = _selectedKind == null || (m['kind'] ?? '') == _selectedKind;
                    return nameOk && kindOk;
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
                        return _avg(b).compareTo(_avg(a));
                    }
                  });

                  if (filtered.isEmpty) return const EmptyState(
                    icon: Icons.directions_car,
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
                        category: h['kind'] ?? '',

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
                          placeType: 'cars',
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
