import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart' show PlaceCard;
import '../clasess/empty_state.dart' show EmptyState;
import '../clasess/SearchField.dart' show SearchField;
import '../clasess/rating_sheet.dart' show RatingService;
import '../clasess/report_dialog.dart' show ReportService;
import '../clasess/offers_section.dart' show OffersPage;

class CraftsPage extends StatefulWidget {
  const CraftsPage({super.key, this.cityFilter, this.isAdmin = false});
  final String? cityFilter;
  final bool isAdmin;

  @override
  State<CraftsPage> createState() => _CraftsPageState();
}

class _CraftsPageState extends State<CraftsPage> {
  String _query = '';
  String _sort = 'top';
  String? _selectedCraft;

  final List<String> _crafts = const ['نجارة', 'خياطة', 'ديكور', 'إكسسوارات/مجوهرات'];
  bool _onlyDelivery = false;
  bool _onlyCustom = false;
  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('crafts');
    if ((widget.cityFilter ?? '').isNotEmpty) {
      return col.where('city', isEqualTo: widget.cityFilter).snapshots();
    }
    return col.snapshots();
  }

  double _avg(Map<String, dynamic> m) {
    final int count = (m['ratingCount'] as int?) ?? 0;
    final double sum = ((m['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.cityFilter == null ? 'الحِرَف اليدوية' : 'الحِرَف اليدوية — ${widget.cityFilter}';

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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersPage()));
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
            // بحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                hintText: 'ابحث باسم الحِرفة/المحل…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            // فلاتر أنواع الحِرف
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _crafts.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final sel = _selectedCraft == null;
                    return ChoiceChip(
                      label: const Text('كل الحِرف'),
                      selected: sel,
                      selectedColor: theme.primaryColor,
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.blueGrey[900]),
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (_) => setState(() => _selectedCraft = null),
                    );
                  }
                  final c = _crafts[i - 1];
                  final sel = _selectedCraft == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: sel,
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(color: sel ? Colors.white : Colors.blueGrey[900]),
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (_) => setState(() => _selectedCraft = c),
                  );
                },
              ),
            ),

            // فلاتر إضافية
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('يعمل بالتوصيل'),
                    selected: _onlyDelivery,
                    onSelected: (v) => setState(() => _onlyDelivery = v),
                  ),
                  FilterChip(
                    label: const Text('حسب الطلب'),
                    selected: _onlyCustom,
                    onSelected: (v) => setState(() => _onlyCustom = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

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
                    icon: Icons.handyman,
                    title: 'لا توجد بيانات',
                    subtitle: 'ابدأ بإضافة حرف يدوية من لوحة الإدارة.',
                  );

                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  final filtered = list.where((m) {
                    final nameOk = (m['name'] ?? '').toString().contains(_query);
                    final cityOk = widget.cityFilter == null || (m['city'] ?? '') == widget.cityFilter;
                    final craftOk = _selectedCraft == null || (m['craft'] ?? '') == _selectedCraft;
                    final deliveryOk = !_onlyDelivery || (m['delivery'] == true);
                    final customOk = !_onlyCustom || (m['customMade'] == true);
                    return nameOk && cityOk && craftOk && deliveryOk && customOk;
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
                    icon: Icons.handyman,
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
                        category: h['craft'] ?? '',

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
                          placeType: 'craft',
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
