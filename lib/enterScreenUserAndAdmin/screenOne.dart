import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// شاشات الأدمن
import '../AdminScreens/AdminOfferPage.dart';
import '../AdminScreens/AdminAdsPage.dart';


// شاشاتك
import '../AdOptionsPage/AdOptionsPageScreen.dart';
import '../AdminScreens/admin_hidden_offers_page.dart';
import '../only_sale_contract/saleScreen2.dart';
import '../onlineScreen/scrrenQne.dart';
import '../screensBottom1/GovernoratesPage.dart';
import '../clasess/logOut.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// 🔍 جلب بيانات المستخدم من Firestore
  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {"role": "guest"};

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists) return {"role": "guest"};

    return doc.data() ?? {"role": "guest"};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? {};
        final role = data['role'] ?? "guest";
        final isAdmin = role == "admin";
        final photoUrl = data['photoUrl'] as String?;
        final name = data['name'] as String? ?? "مستخدم";

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFE0E6ED),
            appBar: AppBar(
              title: Text(
                "الصفحة الرئيسية",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                    name.isNotEmpty ? name[0] : "?",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              ),
              actions: const [LogoutButton()],
            ),
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      // ✅ أقسام للجميع
                      _buildCard(
                        context,
                        Icons.storefront,
                        "إعلانات المحلات",
                            () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                GovernoratesPage(isAdmin: isAdmin),
                          ),
                        ),
                        color: Colors.blue,
                      ),
                      _buildCard(
                        context,
                        Icons.shopping_cart,
                        "إعلانات Online",
                            () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                OnlineScreen(isAdmin: isAdmin),
                          ),
                        ),
                        color: Colors.teal,
                      ),
                      _buildCard(
                        context,
                        Icons.assignment_turned_in,
                        "عقود بيع",
                            () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ContractsHomePage(),
                          ),
                        ),
                        color: Colors.orange,
                      ),
                      _buildCard(
                        context,
                        Icons.add_business,
                        "إضافة متجر / صفحة جديدة",
                            () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdOptionsPage(),
                          ),
                        ),
                        color: Colors.purple,
                      ),

                      // ✅ للأدمن فقط
                      if (isAdmin) ...[
                        _buildCard(
                          context,
                          Icons.pending_actions,
                          "الطلبات الجديدة",
                              () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdminRequestsPage(),
                            ),
                          ),
                          color: Colors.red,
                        ),
                        _buildCard(
                          context,
                          Icons.local_offer,
                          "طلبات العروض",
                              () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                              const AdminOfferRequestsPage(),
                            ),
                          ),
                          color: Colors.deepOrange,
                        ),
                        _buildCard(
                          context,
                          Icons.report_problem,
                          "إدارة البلاغات",
                              () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdminHiddenOffersPage(),
                            ),
                          ),
                          color: Colors.brown,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🟢 دالة مساعدة لبناء الكروت
  Widget _buildCard(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap, {
        Color? color,
      }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color ?? theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
