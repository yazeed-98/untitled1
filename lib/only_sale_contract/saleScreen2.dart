import 'package:flutter/material.dart';
import 'package:untitled1/only_sale_contract/saleScreen.dart';
import 'only_sale_contract_page.dart';

class ContractsHomePage extends StatefulWidget {
  const ContractsHomePage({super.key});

  @override
  State<ContractsHomePage> createState() => _ContractsHomePageState();
}

class _ContractsHomePageState extends State<ContractsHomePage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العقود'),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // إنشاء عقد جديد
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.note_add),
                    label: const Text('إنشاء عقد جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NameOnlySaleContractPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // الذهاب إلى قائمة العقود
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.folder_open, color: colors.primary),
                    label: Text(
                      'عقودي',
                      style: TextStyle(color: colors.primary, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.primary, width: 2),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContractsListPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: colors.primary.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
