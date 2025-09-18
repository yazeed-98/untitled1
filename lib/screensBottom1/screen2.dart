import 'package:flutter/material.dart';
import '../clasess/CategoryFilterWidget.dart';
import '../clasess/CustomAppBar.dart';
import '../clasess/offers_section.dart';

class CategoriesScreen extends StatefulWidget {
  final String governorate; // المحافظة المختارة
  final bool isAdmin;

  const CategoriesScreen({
    super.key,
    required this.governorate,
    this.isAdmin = false,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<_Category> categories = const [
    _Category('مطاعم', Icons.restaurant, Colors.teal, 'restaurants'),
    _Category('فنادق / شقق سكنية', Icons.hotel, Colors.indigo, 'hotels'),
    _Category('محلات بيع الملابس', Icons.shopping_bag, Colors.pink, 'clothing_shops'),
    _Category('بنوك وشركات تمويل', Icons.account_balance, Colors.blue, 'finance_providers'),
    _Category('قسم طبي (عيادات / مستشفيات)', Icons.local_hospital, Colors.red, 'medical'),
    _Category('الحرف اليدوية', Icons.handyman, Colors.deepOrange, 'crafts'),
    _Category('مؤسسات تعليمية', Icons.school, Colors.green, 'education'),
    _Category('محلات بيع التجزئه', Icons.shopping_cart, Colors.brown, 'wholesale'),
    _Category('الإلكترونيات', Icons.devices, Colors.blueGrey, 'electronics'),
    _Category('الهيئات والمنظمات', Icons.groups, Colors.amber, 'organizations'),
    _Category('السيارات', Icons.directions_car, Colors.deepPurple, 'cars'),
  ];

  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    final filtered = q.isEmpty
        ? categories
        : categories.where((c) => c.title.contains(q)).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
          title: const Text('الأقسام'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Column(
          children: [
            // ✅ شريط البحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (val) => setState(() => query = val),
                decoration: InputDecoration(
                  hintText: 'ابحث عن قسم…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ✅ شبكة الأقسام
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: .95,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _CategoryCard(
                    title: item.title,
                    icon: item.icon,
                    color: item.color,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GenericCategoryPage(
                            title: item.title,
                            collection: item.pageName,
                            cityFilter: widget.governorate,
                            isAdmin: widget.isAdmin,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ✅ صفحة فرعية عامة لكل الأقسام
class GenericCategoryPage extends StatefulWidget {
  final String title;
  final String collection;
  final String? cityFilter;
  final bool isAdmin;

  const GenericCategoryPage({
    super.key,
    required this.title,
    required this.collection,
    this.cityFilter,
    this.isAdmin = false,
  });

  @override
  State<GenericCategoryPage> createState() => _GenericCategoryPageState();
}

class _GenericCategoryPageState extends State<GenericCategoryPage> {
  String _sort = 'top';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        actions: [
          IconButton(
            tooltip: "العروض",
            icon: const Icon(Icons.local_offer_outlined, color: Colors.teal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OffersPage(isAdmin: widget.isAdmin)),
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
            icon: const Icon(Icons.sort, color: Colors.blue),
          ),
        ],
      ),
      body: CategoryFilterWidget(
        collection: widget.collection,
        cityFilter: widget.cityFilter,
        isAdmin: widget.isAdmin,
        sortBy: _sort,
      ),
    );
  }
}

// ✅ موديل القسم
class _Category {
  final String title;
  final IconData icon;
  final Color color;
  final String pageName;
  const _Category(this.title, this.icon, this.color, this.pageName);
}

// ✅ بطاقة القسم (الشكل القديم المحسّن)
class _CategoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        widget.color.withOpacity(0.95),
        widget.color.withOpacity(0.75),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.97 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(top: -30, left: -20, child: _bubble(70, 0.10)),
                Positioned(bottom: -20, right: -25, child: _bubble(90, 0.08)),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(widget.icon, size: 30, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}
