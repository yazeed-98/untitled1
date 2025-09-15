import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/app_snackbar.dart';

class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  String? storeType; // متجر أو أونلاين
  String? selectedCollection;

  final Map<String, String> storeCollections = {
    "hotels": "فنادق",
    "finance_providers": "خدمات مالية",
    "cars": "سيارات",
    "clothing_shops": "ملابس",
    "crafts": "حرف يدوية",
    "education": "تعليم",
    "electronics": "إلكترونيات",
    "medical": "طبي",
    "organizations": "مؤسسات",
    "restaurants": "مطاعم",
    "wholesale": "تجارة جملة",
  };
  final Map<String, String> onlineCollections = {
    "courses": "دورات",
    "digitalServices": "خدمات رقمية",
    "onlineStores": "متاجر إلكترونية",
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || storeType == null || selectedCollection == null) {
      AppSnackBar.show(context, "يرجى تعبئة جميع الحقول",
          backgroundColor: Colors.orange, icon: Icons.error);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("requests").add({
        "collection": selectedCollection,
        "type": storeType,
        "name": nameController.text.trim(),
        "description": descriptionController.text.trim(),
        "city": cityController.text.trim(),
        "phone": phoneController.text.trim(),
        "imageUrl": imageUrlController.text.trim(),
        "approved": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        AppSnackBar.show(context, "تم إرسال الطلب بانتظار موافقة الأدمن",
            backgroundColor: Colors.green, icon: Icons.check_circle);

        nameController.clear();
        descriptionController.clear();
        cityController.clear();
        phoneController.clear();
        imageUrlController.clear();
        setState(() {
          storeType = null;
          selectedCollection = null;
        });
      }
    } catch (e) {
      AppSnackBar.show(context, "حدث خطأ أثناء إرسال الطلب",
          backgroundColor: Colors.red, icon: Icons.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تسجيل متجر / أونلاين"),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: storeType,
                  items: const [
                    DropdownMenuItem(value: "store", child: Text("متجر")),
                    DropdownMenuItem(value: "online", child: Text("أونلاين")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      storeType = val;
                      selectedCollection = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "اختر النوع",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null ? "هذا الحقل مطلوب" : null,
                ),
                const SizedBox(height: 16),

                if (storeType != null)
                  DropdownButtonFormField<String>(
                    value: selectedCollection,
                    items: (storeType == "store" ? storeCollections : onlineCollections)
                        .entries
                        .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCollection = val),
                    decoration: const InputDecoration(
                      labelText: "اختر القسم",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null ? "هذا الحقل مطلوب" : null,
                  ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "اسم المتجر / الأونلاين",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "يرجى إدخال الاسم"
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "الوصف",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "يرجى إدخال الوصف"
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: "المدينة",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "يرجى إدخال المدينة"
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "رقم الهاتف",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "يرجى إدخال رقم الهاتف"
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: imageUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: "رابط الصورة",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text("إرسال الطلب"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
