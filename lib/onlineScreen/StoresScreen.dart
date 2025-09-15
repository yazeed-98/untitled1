import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Widgets/Services خارجية
import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart' show PlaceCard;
import '../clasess/empty_state.dart' show EmptyState;
import '../clasess/SearchField.dart' show SearchField;
import '../clasess/offers_section.dart';
import '../clasess/rating_sheet.dart' show RatingService;
import '../clasess/report_dialog.dart' show ReportService;


class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key, this.isAdmin = false});
  final bool isAdmin;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String _query = '';
  String _sort = 'top';
  String? _selectedCategory;

  final List<String> _categories = const [
    'برمجة',
    'تداول',
    'تسويق',
    'لغات',
    'أخرى',
  ];

  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    Query<Map<String, dynamic>> col =
    FirebaseFirestore.instance.collection('courses');
    if (_selectedCategory != null) {
      col = col.where('category', isEqualTo: _selectedCategory);
    }
    return col.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: const Text('التعليم والتدريب الأونلاين'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: theme.primaryColorDark,
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
            // 🔍 البحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                hintText: 'ابحث باسم الدورة…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            // 🔹 الفلاتر
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final sel = _selectedCategory == null;
                      return ChoiceChip(
                        label: Text(
                          'الكل',
                          style: TextStyle(
                            color: sel ? Colors.white : theme.primaryColorDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: sel,
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: sel ? Colors.teal : Colors.grey.shade400),
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = null),
                      );
                    }
                    final cat = _categories[i - 1];
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: _selectedCategory == cat
                              ? Colors.white
                              : theme.primaryColorDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: _selectedCategory == cat,
                      selectedColor: Colors.teal,
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedCategory == cat
                              ? Colors.teal
                              : Colors.grey.shade400,
                        ),
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
            ),

            // 📋 قائمة الدورات
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
                      icon: Icons.school,
                      title: 'لا توجد دورات',
                      subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                    );
                  }

                  final list = docs.map((d) {
                    final m = {...d.data()!};
                    m['id'] = d.id;
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  // فلترة البحث
                  final filtered = list.where((c) {
                    return (c['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_query.toLowerCase());
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
                      icon: Icons.school,
                      title: 'لا توجد نتائج مطابقة',
                      subtitle: 'جرّب تعديل البحث أو الفلاتر.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final avg = _avg(c);
                      final id = c['id'] as String;
                      final ref =
                      c['ref'] as DocumentReference<Map<String, dynamic>>;

                      return PlaceCard(
                        title: (c['name'] ?? '') as String,
                        city: (c['instructor'] ?? '') as String,
                        category: (c['category'] ?? '') as String,
                        imageUrl: (c['image'] ?? '') as String,
                        rating: avg,
                        ratingCount: (c['ratingCount'] as int?) ?? 0,
                        isFavorite: _favs.contains(id),
                        onFavoriteChanged: (v) => setState(() {
                          v ? _favs.add(id) : _favs.remove(id);
                        }),
                        ref: ref,
                        isAdmin: widget.isAdmin,
                        onRate: () => RatingService.rateRestaurant(
                          context,
                          ref: ref,
                          placeName: (c['name'] ?? '') as String,
                        ),
                        onReport: () => ReportService.reportPlace(
                          context,
                          placeType: 'course',
                          placeId: id,
                          placeName: (c['name'] ?? '') as String,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaceDetailsPage(placeData: c),


                              ));

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
