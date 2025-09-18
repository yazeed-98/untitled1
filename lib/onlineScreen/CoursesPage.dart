// lib/screensBottom1/courses_page.dart
import 'package:flutter/material.dart';
import '../clasess/CustomAppBar.dart';
import '../clasess/offersDetail.dart';
import '../clasess/offers_section.dart';
import '../clasess/CategoryFilterWidget.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String _sort = 'top';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'التعليم والتدريب الأونلاين',
          actions: [
            IconButton(
              tooltip: "العروض",
              icon: const Icon(Icons.local_offer_outlined,
              color: Colors.green,),
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
                PopupMenuItem(value: 'cheap', child: Text('الأرخص')),
                PopupMenuItem(value: 'name', child: Text('الاسم (أ-ي)')),
              ],
              icon: const Icon(Icons.sort, color: Colors.blue),
            ),
          ],
        ),
        body: CategoryFilterWidget(
          collection: 'courses',
          isAdmin: widget.isAdmin,
          sortBy: _sort,
        ),
      ),
    );
  }
}
