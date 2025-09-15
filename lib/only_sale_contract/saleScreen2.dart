import 'package:flutter/material.dart';
import 'package:untitled1/only_sale_contract/saleScreen.dart';

// إنشاء عقد جديد
import 'only_sale_contract_page.dart';
// تفاصيل العقد
import 'package:untitled1/only_sale_contract/saleScreen2.dart';


class ContractsHomePage extends StatefulWidget {
  const ContractsHomePage({super.key});

  @override
  State<ContractsHomePage> createState() => _ContractsHomePageState();
}

class _ContractsHomePageState extends State<ContractsHomePage> {
  final _contractIdCtrl = TextEditingController();

  @override
  void dispose() {
    _contractIdCtrl.dispose();
    super.dispose();
  }

  void _openDetailsById() {
    final id = _contractIdCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل معرّف العقد أولًا')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NameOnlySaleContractPage(contractId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('العقود')),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NameOnlySaleContractPage(contractId: '' ),
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
                    icon: const Icon(Icons.folder_open),
                    label: const Text('عقودي'),
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

                 SizedBox(height: 24),
                Divider(),
                 SizedBox(height: 16),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
