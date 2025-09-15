// lib/screensBottom1/education_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Widgets / Classes خارجية
import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart' show PlaceCard;
import '../clasess/empty_state.dart' show EmptyState;
import '../clasess/rating_sheet.dart' show RatingService;
import '../clasess/report_dialog.dart' show ReportService, ReportResult;
import '../clasess/SearchField.dart' show SearchField;
import '../clasess/offers_section.dart' show OffersPage;

class EducationPage extends StatefulWidget {
  const EducationPage({super.key, this.cityFilter, this.isAdmin = false});
  final String? cityFilter;
  final bool isAdmin;

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  String _query = '';
  String _sort = 'top';
  String? _selectedType;
  bool _onlyPrivate = false;
  bool _onlyRemote = false;
  final Set<String> _favs = {};
  final List<String> _types = const [
    'مدرسة',
    'جامعة',
    'كلية',
    'اكادميه',
    'مركز تدريب',
    'روضة',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('education');
    if ((widget.cityFilter ?? '').isNotEmpty) {
      return col.where('city', isEqualTo: widget.cityFilter).snapshots();
    }
    return col.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: const Text('المؤسسات التعليميه', style: TextStyle(fontSize: 20)),
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OffersPage()),
              ),
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
                hintText: 'ابحث باسم المؤسسة…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            // فلاتر الأنواع
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _types.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return ChoiceChip(
                      label: const Text('كل الأنواع'),
                      selected: _selectedType == null,
                      onSelected: (_) => setState(() => _selectedType = null),
                    );
                  }
                  final t = _types[i - 1];
                  return ChoiceChip(
                    label: Text(t),
                    selected: _selectedType == t,
                    onSelected: (sel) => setState(() => _selectedType = sel ? t : null),
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
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('تعليم عن بُعد'),
                      selected: _onlyRemote,
                      onSelected: (v) => setState(() => _onlyRemote = v),
                    ),
                    FilterChip(
                      label: const Text('خاص'),
                      selected: _onlyPrivate,
                      onSelected: (v) => setState(() => _onlyPrivate = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // بيانات المؤسسات
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
                    icon: Icons.school,
                    title: 'لا توجد بيانات',
                    subtitle: 'ابدأ بإضافة مؤسسات تعليمية من لوحة الإدارة.',
                  );

                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['id'] = d.id;
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  final filtered = list.where((m) {
                    final nameOk = (m['name'] ?? '').toString().contains(_query);
                    final cityOk = widget.cityFilter == null || (m['city'] ?? '') == widget.cityFilter;
                    final typeOk = _selectedType == null || (m['type'] ?? '') == _selectedType;
                    final privateOk = !_onlyPrivate || (m['isPrivate'] == true);
                    final remoteOk = !_onlyRemote || (m['remote'] == true);
                    return nameOk && cityOk && typeOk && privateOk && remoteOk;
                  }).toList();

                  filtered.sort((a, b) {
                    switch (_sort) {
                      case 'cheap':
                        return ((a['price'] as num?) ?? 1).compareTo((b['price'] as num?) ?? 1);
                      case 'name':
                        return ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String);
                      default:
                        return _avg(b).compareTo(_avg(a));
                    }
                  });

                  if (filtered.isEmpty) return const EmptyState(
                    icon: Icons.school,
                    title: 'لا توجد نتائج مطابقة',
                    subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                  );

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
                        onFavoriteChanged: (v) => setState(() => v ? _favs.add(id) : _favs.remove(id)),
                        ref: ref,
                        isAdmin: widget.isAdmin,
                        onRate: () => RatingService.rateRestaurant(context, ref: ref, placeName: (h['name'] ?? '') as String),
                        onReport: () => ReportService.reportPlace(
                          context, placeType: 'education', placeId: id, placeName: (h['name'] ?? '') as String,
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
    final count = (m['ratingCount'] as int?) ?? 0;
    final sum = ((m['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }
}
