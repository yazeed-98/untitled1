// lib/screensBottom1/organizations_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Widgets / Classes خارجية
import '../clasess/card.dart'            show PlaceCard;
import '../clasess/empty_state.dart'     show EmptyState;
import '../clasess/offers_section.dart';
import '../clasess/rating_sheet.dart'    show RatingService, RatingSheet;
import '../clasess/report_dialog.dart'   show ReportDialog, ReportResult, ReportService;
import '../clasess/SearchField.dart'     show SearchField;
import '../clasess/ShinyIconBadge.dart'  show ShinyIconBadge;

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key, this.cityFilter,  this.isAdmin=false});
  final String? cityFilter; // فلترة بالمحافظة (اختياري)
  final bool isAdmin;
  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  // بحث + فرز
  String _query = '';
  String _sort  = 'top'; // top | cheap | name

  // فلاتر النوع (خيرية/منظمة/مركز تدريب)
  String? _selectedType;
  final List<String> _types = const ['هيئات ', 'منظمات', 'مراكز تدريب مهني'];

  // فلاتر قطاع النشاط (اختياري)
  String? _selectedSector;
  final List<String> _sectors = const ['تعليم', 'صحة', 'تدريب تقني',  'خدمات مجتمعية'];

  // فلاتر إضافية
  bool _onlyFree       = false; // خدمات/دورات مجانية
  bool _onlyCertified  = false; // شهادات معتمدة (تنفع لمراكز التدريب)

  // مفضلات محليًا
  final Set<String> _favs = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final col = FirebaseFirestore.instance.collection('organizations');
    if ((widget.cityFilter ?? '').isNotEmpty) {
      return col.where('city', isEqualTo: widget.cityFilter).snapshots();
    }
    return col.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.cityFilter == null
        ? 'الهيئات والمنظمات'
        : 'الهيئات والمنظمات — ${widget.cityFilter}';

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
                PopupMenuItem(value: 'top',   child: Text('الأعلى تقييمًا')),
                PopupMenuItem(value: 'cheap', child: Text('الأقل تكلفة')),
                PopupMenuItem(value: 'name',  child: Text('الاسم (أ-ي)')),
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
                hintText: 'ابحث باسم الجهة…',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            // فلاتر النوع
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _types.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final sel = _selectedType == null;
                    return ChoiceChip(
                      label: const Text('كل الأنواع'),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedType = null),
                    );
                  }
                  final t = _types[i - 1];
                  return ChoiceChip(
                    label: Text(t),
                    selected: _selectedType == t,
                    onSelected: (isSel) => setState(() => _selectedType = isSel ? t : null),
                  );
                },
              ),
            ),

            // فلاتر القطاع
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                scrollDirection: Axis.horizontal,
                itemCount: _sectors.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final sel = _selectedSector == null;
                    return ChoiceChip(
                      label: const Text('كل القطاعات'),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedSector = null),
                    );
                  }
                  final s = _sectors[i - 1];
                  return ChoiceChip(
                    label: Text(s),
                    selected: _selectedSector == s,
                    onSelected: (isSel) => setState(() => _selectedSector = isSel ? s : null),
                  );
                },
              ),
            ),

            // فلاتر إضافية
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('مجاني'),
                      selected: _onlyFree,
                      onSelected: (v) => setState(() => _onlyFree = v),
                    ),
                    FilterChip(
                      label: const Text('شهادات معتمدة'),
                      selected: _onlyCertified,
                      onSelected: (v) => setState(() => _onlyCertified = v),
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
                      icon: Icons.groups,
                      title: 'لا توجد بيانات',
                      subtitle: 'ابدأ بإضافة جهات من لوحة الإدارة.',
                    );
                  }

                  // تحويل المستندات إلى خرائط + إضافة id/ref
                  final list = docs.map((d) {
                    final m = {...d.data()};
                    m['id']  = d.id;
                    m['ref'] = d.reference;
                    return m;
                  }).toList();

                  // فلترة واجهة
                  final filtered = list.where((m) {
                    final nameOk = (m['name'] ?? '').toString().contains(_query);
                    final cityOk = widget.cityFilter == null || (m['city'] ?? '') == widget.cityFilter;

                    final typeOk   = _selectedType   == null || (m['type']   ?? '') == _selectedType;
                    final sectorOk = _selectedSector == null || (m['sector'] ?? '') == _selectedSector;

                    final freeOk      = !_onlyFree      || (m['free']      == true);
                    final certOk      = !_onlyCertified || (m['certified'] == true);

                    return nameOk && cityOk && typeOk && sectorOk && freeOk && certOk;
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
                      icon: Icons.groups,
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
                      final ref =
                      h['ref'] as DocumentReference<Map<String, dynamic>>;

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
                          // TODO: افتح صفحة تفاصيل الفندق
                        },
                      );
                    },
                  );                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // متوسط التقييم
  double _avg(Map<String, dynamic> m) {
    final int count  = (m['ratingCount'] as int?) ?? 0;
    final double sum = ((m['ratingSum'] as num?)?.toDouble()) ?? 0.0;
    return count == 0 ? 0.0 : sum / count;
  }

  // حفظ التقييم
  Future<void> _submitRating(
      DocumentReference<Map<String, dynamic>> ref,
      double value,
      ) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap  = await tx.get(ref);
      final data  = snap.data() ?? {};
      final sum   = (data['ratingSum'] as num?)?.toDouble() ?? 0.0;
      final count = (data['ratingCount'] as int?) ?? 0;
      tx.update(ref, {
        'ratingSum': sum + value,
        'ratingCount': count + 1,
      });
    });

    try {
      await ref.collection('ratings').add({
        'value': value,
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // إرسال البلاغ
  Future<void> _sendReport({
    required String orgId,
    required String orgName,
    required String orgType,
    required String sector,
    required ReportResult result,
  }) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'placeType': 'organization',
      'orgId': orgId,
      'orgName': orgName,
      'orgType': orgType,
      'sector': sector,
      'type': result.type,
      'details': result.details ?? '',
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  IconData _iconFor(String type, String sector) {
    // أولاً جرّب القطاع، وإلا رجع أيقونة حسب النوع
    switch (sector) {
      case 'تعليم':         return Icons.school;
      case 'صحة':           return Icons.local_hospital;
      case 'تمكين':         return Icons.volunteer_activism;
      case 'تدريب تقني':    return Icons.computer;
      case 'حِرَف':         return Icons.handyman;
      case 'خدمات مجتمعية': return Icons.groups_2;
    }
    switch (type) {
      case ' هيئات ':   return Icons.volunteer_activism;
      case 'منظمات':         return Icons.apartment;
      case 'مراكز تدريب مهني': return Icons.build;
      default:              return Icons.groups;
    }
  }
}
