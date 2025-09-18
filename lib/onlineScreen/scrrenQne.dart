import 'package:flutter/material.dart';

import 'CoursesPage.dart';
import 'StoresScreen.dart';
import 'digitalServices.dart';

class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key, required bool isAdmin});

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> {
  final List<_OnlineCategory> categories = const [
    _OnlineCategory('المتاجر الإلكترونية', Icons.store, Colors.blue),

    _OnlineCategory('التعليم والتدريب الأونلاين', Icons.school, Colors.orange),
    _OnlineCategory('الخدمات الرقمية', Icons.devices, Colors.purple),
  ];

  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final List<_OnlineCategory> filtered = q.isEmpty
        ? categories
        : categories.where((c) => c.title.toLowerCase().contains(q)).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
          title: const Text('الأونلاين'),
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
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final cross = w >= 1100 ? 4 : (w >= 800 ? 3 : 2);

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
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
                          if (item.title == 'المتاجر الإلكترونية') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OnlineStoresPage()),
                            );
                          } else if (item.title == 'التعليم والتدريب الأونلاين') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CoursesPage()),
                            );
                          } else if (item.title == 'الخدمات الرقمية') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DigitalServicesPage()),
                            );
                          }
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

// ✅ موديل القسم
class _OnlineCategory {
  final String title;
  final IconData icon;
  final Color color;
  const _OnlineCategory(this.title, this.icon, this.color);
}

// ✅ كرت القسم
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
          scale: _pressed ? 0.98 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.22),
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
