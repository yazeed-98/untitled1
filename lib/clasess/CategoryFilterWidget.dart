// lib/clasess/category_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../clasess/PlaceDetailsPage.dart';
import '../clasess/card.dart';
import '../clasess/rating_sheet.dart';
import '../clasess/report_service.dart';

class CategoryFilterWidget extends StatefulWidget {
  final String collection; // اسم الكولكشن
  final String? cityFilter;
  final bool isAdmin;
  final String? sortBy; // 👈 للفرز (top, cheap, name)

  const CategoryFilterWidget({
    super.key,
    required this.collection,
    this.cityFilter,
    this.isAdmin = false,
    this.sortBy,
  });

  @override
  State<CategoryFilterWidget> createState() => _CategoryFilterWidgetState();
}

class _CategoryFilterWidgetState extends State<CategoryFilterWidget> {
  String? selectedSubCategory;
  String _searchQuery = '';
  final Set<String> _favs = {};

  /// 🟢 كل التصنيفات الفرعية جاهزة بخريطة واحدة
  final Map<String, List<String>> subCategoriesMap = {
    'restaurants': ['مطاعم عربية', 'مطاعم سياحيه', 'كافيه', 'وجبات سريعة'],
    'hotels': ['فنادق فاخرة', 'فنادق متوسطة', 'شقق مفروشة'],
    'clothing_shops': ['ملابس رجالية', 'ملابس نسائية', 'ملابس أطفال'],
    'finance_providers': ['بنوك', 'شركات تمويل', 'محافظ الكترونيه'],
    'medical': ['عيادات', 'مستشفيات', 'صيدليات'],
    'crafts': ['صيانة اجهزه كهربائيه', 'نجار', 'حداد'],
    'education': ['مدارس', 'جامعات', 'اكاديميات'],
    'wholesale': ['سوبر ماركت', 'أدوات منزلية'],
    'electronics': ['هواتف', 'أجهزة كمبيوتر', 'إكسسوارات'],
    'organizations': ['جمعيات', 'مؤسسات خيرية', 'هيئات رسمية'],
    'cars': ['بيع سيارات', 'محلات زينة السيارات', 'مراكز صيانة'],

    // ✅ الأقسام الأونلاين
    'online_stores': ['صفحات انستقرام', 'صفحات فيسبوك', 'تطبيقات', 'مواقع'],
    'courses': ['دورات مجانية', 'شهادات معتمدة', 'تدريب عن بعد'],
    'digital_services': ['برمجة', 'تصميم', 'تسويق رقمي'],
  };

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    Query<Map<String, dynamic>> col =
    FirebaseFirestore.instance.collection(widget.collection);

    if ((widget.cityFilter ?? '').isNotEmpty) {
      col = col.where('city', isEqualTo: widget.cityFilter);
    }
    if (selectedSubCategory != null && selectedSubCategory != 'الكل') {
      col = col.where('category', isEqualTo: selectedSubCategory);
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
    final subCategories = ['الكل', ..._getSubCategories(widget.collection)];

    return Column(
      children: [
        // 🔍 شريط البحث
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),

        // ✅ فلاتر (Chips)
        if (subCategories.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: subCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = subCategories[i];
                final selected = selectedSubCategory == cat ||
                    (selectedSubCategory == null && cat == 'الكل');
                return ChoiceChip(
                  label: Text(cat, style: GoogleFonts.cairo()),
                  selected: selected,
                  selectedColor: Colors.blue.shade600,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                  ),
                  onSelected: (_) {
                    setState(() =>
                    selectedSubCategory = cat == 'الكل' ? null : cat);
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 12),

        // ✅ عرض البيانات
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('لا توجد بيانات متاحة'));
              }

              var list = docs
                  .map((d) {
                final m = {...d.data()};
                m['id'] = d.id;
                m['ref'] = d.reference;
                return m;
              })
                  .where((m) => (m['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
                  .toList();

              // ✅ الفرز
              if (widget.sortBy != null) {
                switch (widget.sortBy) {
                  case 'cheap':
                    if (widget.collection == 'finance_providers') {
                      list.sort((a, b) => ((a['feeLevel'] ?? 0) as num)
                          .compareTo((b['feeLevel'] ?? 0) as num));
                    } else {
                      list.sort((a, b) => ((a['price'] ?? 0) as num)
                          .compareTo((b['price'] ?? 0) as num));
                    }
                    break;
                  case 'name':
                    list.sort((a, b) =>
                        (a['name'] ?? '').compareTo(b['name'] ?? ''));
                    break;
                  case 'top':
                  default:
                    list.sort((a, b) => _avg(b).compareTo(_avg(a)));
                }
              }

              if (list.isEmpty) {
                return const Center(child: Text('لا توجد نتائج مطابقة'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final m = list[i];
                  final avg = _avg(m);
                  final id = m['id'] as String;

                  return PlaceCard(
                    title: (m['name'] ?? '') as String,
                    city: (m['city'] ?? '') as String,
                    category: (m['category'] ?? '') as String,
                    imageUrl: (m['imageUrl'] ?? m['image'] ?? '') as String,
                    rating: avg,
                    ratingCount: (m['ratingCount'] as int?) ?? 0,
                    isFavorite: _favs.contains(id),
                    onFavoriteChanged: (v) => setState(() {
                      v ? _favs.add(id) : _favs.remove(id);
                    }),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailsPage(placeData: m),
                        ),
                      );
                    },
                    onRate: () => RatingService.ratePlace(
                      context,
                      ref: m['ref'],
                      placeName: m['name'] ?? '',
                    ),
                    onReport: () => ReportService.reportPlace(
                      context,
                      placeType: widget.collection,
                      placeId: id,
                      placeName: m['name'] ?? '',
                    ),
                    ref: m['ref'],
                    isAdmin: widget.isAdmin,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🟢 إرجاع التصنيفات الفرعية حسب الكولكشن
  List<String> _getSubCategories(String collection) {
    return subCategoriesMap[collection] ?? [];
  }
}
