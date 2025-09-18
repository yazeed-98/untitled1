import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? storeType;
  String? selectedCollection;
  String? selectedGovernorate;
  String? selectedSubCategory;

  /// الأقسام للمتاجر
  final Map<String, String> storeCollections = {
    "restaurants": "مطاعم",
    "hotels": "فنادق",
    "finance_providers": "بنوك ",
    "cars": "سيارات",
    "clothing_shops": "ملابس",
    "crafts": "حرف يدوية",
    "education": "تعليم",
    "electronics": "إلكترونيات",
    "medical": "طبي",
    "organizations": "مؤسسات",
    "wholesale": "تجارة جملة",
  };

  /// الأقسام للأونلاين
  final Map<String, String> onlineCollections = {
    "courses": "دورات",
    "digital_services": "خدمات رقمية",
    "online_stores": "متاجر إلكترونية",
  };

  /// المحافظات
  final List<String> governorates = const [
    'عمّان',
    'إربد',
    'الزرقاء',
    'العقبة',
    'الكرك',
    'الطفيلة',
    'مأدبا',
    'جرش',
    'عجلون',
    'المفرق',
    'معان',
  ];

  /// التصنيفات الفرعية
  List<String> getSubCategories(String? collection) {
    switch (collection) {
      case 'restaurants':
        return ['مطاعم عربية', 'مطاعم سياحية', 'كافيه', 'وجبات سريعة'];
      case 'hotels':
        return ['فنادق فاخرة', 'فنادق متوسطة', 'شقق مفروشة'];
      case 'clothing_shops':
        return ['ملابس رجالية', 'ملابس نسائية', 'ملابس أطفال'];
      case 'finance_providers':
        return ['بنوك', 'شركات تمويل', 'محافظ إلكترونية'];
      case 'medical':
        return ['عيادات', 'مستشفيات', 'صيدليات'];
      case 'crafts':
        return ['صيانة أجهزة كهربائية', 'نجار', 'حداد'];
      case 'education':
        return ['مدارس', 'جامعات', 'أكاديميات'];
      case 'wholesale':
        return ['سوبر ماركت', 'أدوات منزلية'];
      case 'electronics':
        return ['هواتف', 'أجهزة كمبيوتر', 'إكسسوارات'];
      case 'organizations':
        return ['جمعيات', 'مؤسسات خيرية', 'هيئات رسمية'];
      case 'cars':
        return ['بيع سيارات', 'محلات زينة السيارات', 'مراكز صيانة'];

    // ✅ للأونلاين
      case 'online_stores':
        return ['تطبيقات','متاجر إلكترونية', 'مواقع التواصل الاجتماعي '];
      case 'courses':
        return ['تطبيقات ', ' مواقع تواصل اجتماعي   '];
      case 'digital_services':
        return ['خدمات برمجة', 'خدمات تصميم'];

      default:
        return [];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        storeType == null ||
        selectedCollection == null ||
        (storeType == "store" && selectedGovernorate == null)) {
      AppSnackBar.show(
        context,
        "يرجى تعبئة جميع الحقول",
        backgroundColor: Colors.orange,
        icon: Icons.error,
      );
      return;
    }

    try {
      final data = {
        "collection": selectedCollection,
        "subCategory": selectedSubCategory,
        "type": storeType,
        "name": nameController.text.trim(),
        "description": descriptionController.text.trim(),
        "phone": phoneController.text.trim(),
        "imageUrl": imageUrlController.text.trim(),
        "approved": false,
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (storeType == "store") {
        data["city"] = selectedGovernorate;
        data["location"] = locationController.text.trim();
      }

      await FirebaseFirestore.instance.collection("requests").add(data);

      if (context.mounted) {
        AppSnackBar.show(
          context,
          "تم إرسال الطلب بانتظار موافقة الأدمن",
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        nameController.clear();
        descriptionController.clear();
        phoneController.clear();
        imageUrlController.clear();
        locationController.clear();
        setState(() {
          storeType = null;
          selectedCollection = null;
          selectedGovernorate = null;
          selectedSubCategory = null;
        });
      }
    } catch (e) {
      AppSnackBar.show(
        context,
        "حدث خطأ أثناء إرسال الطلب",
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تسجيل متجر / أونلاين"),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // النوع
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
                      selectedSubCategory = null;
                      selectedGovernorate = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "اختر النوع",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null ? "هذا الحقل مطلوب" : null,
                ),
                const SizedBox(height: 16),

                // القسم
                if (storeType != null)
                  DropdownButtonFormField<String>(
                    value: selectedCollection,
                    items: (storeType == "store"
                        ? storeCollections
                        : onlineCollections)
                        .entries
                        .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCollection = val;
                        selectedSubCategory = null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "اختر القسم",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                    val == null ? "هذا الحقل مطلوب" : null,
                  ),
                const SizedBox(height: 16),

                // التصنيف الفرعي
                if (selectedCollection != null &&
                    getSubCategories(selectedCollection).isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedSubCategory,
                    items: getSubCategories(selectedCollection!)
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedSubCategory = val),
                    decoration: const InputDecoration(
                      labelText: "اختر التصنيف الفرعي",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                    val == null ? "هذا الحقل مطلوب" : null,
                  ),
                if (selectedCollection != null &&
                    getSubCategories(selectedCollection).isNotEmpty)
                  const SizedBox(height: 16),

                // الاسم
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

                // الوصف
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

                // المحافظة + الموقع
                if (storeType == "store")
                  DropdownButtonFormField<String>(
                    value: selectedGovernorate,
                    items: governorates
                        .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(g),
                    ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedGovernorate = val),
                    decoration: const InputDecoration(
                      labelText: "اختر المحافظة",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                    val == null ? "يرجى اختيار المحافظة" : null,
                  ),
                if (storeType == "store") const SizedBox(height: 16),

                if (storeType == "store")
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: "الموقع (العنوان بالتفصيل)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "يرجى إدخال الموقع"
                        : null,
                  ),
                if (storeType == "store") const SizedBox(height: 16),

                // الهاتف
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

                // الصورة
                TextFormField(
                  controller: imageUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: "رابط الصورة",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // زر الإرسال
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text("إرسال الطلب"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
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
