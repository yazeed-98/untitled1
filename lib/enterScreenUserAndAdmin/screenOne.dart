import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../AdOptionsPage/AdOptionsPageScreen.dart';
import '../AdminScreens/AdminAdsPage.dart';
import '../clasess/logOut.dart';
import '../onlineScreen/scrrenQne.dart';
import '../only_sale_contract/saleScreen2.dart';
import '../screensBottom1/GovernoratesPage.dart';



class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<bool> _checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    return doc.data()?['role'] == 'admin';
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<bool>(
      future: _checkIfAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = snapshot.data ?? false;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor:const Color(0xFFE0E6ED), // رمادي أغمق شوي

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
                  child: Icon(Icons.person, color: theme.colorScheme.primary),
                ),
              ),
              actions: [
                const
                LogoutButton(),
              ],
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
                            builder: (context) => const GovernoratesPage(),
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
                            builder: (context) => const OnlineScreen(),
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
                        // _buildCard(
                          // context,
                          // Icons.check_circle,
                          // "الإعلانات المقبولة",
                              // () => Navigator.of(context).push(
                            // MaterialPageRoute(
                            //   builder: (context) => const AdminAdsPage(),
                            // ),
                          // ),
                          // color: Colors.green,
                        // ),
                        // _buildCard(
                        //   context,
                        //   Icons.cancel,
                        //   "الإعلانات المرفوضة",
                        //       () => Navigator.of(context).push(
                        //     MaterialPageRoute(
                        //       builder: (context) => const AdminRejectedAdsPage(),
                        //     ),
                        //   ),
                        //   color: Colors.grey,
                        // ),
                      ]
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
