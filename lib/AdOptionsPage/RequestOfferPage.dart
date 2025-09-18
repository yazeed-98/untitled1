import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/app_snackbar.dart';

class NewOfferRequestPage extends StatefulWidget {
  const NewOfferRequestPage({super.key});

  @override
  State<NewOfferRequestPage> createState() => _NewOfferRequestPageState();
}

class _NewOfferRequestPageState extends State<NewOfferRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _loading = false;

  final Map<String, List<String>> mainCollections = {
    "المتاجر": ["restaurants", "hotels", "clothing_shops", "cars"],
    "الأونلاين": ["online_stores", "courses", "digital_services"],
    "خدمات أخرى": [
      "medical",
      "education",
      "finance_providers",
      "crafts",
      "organizations",
      "wholesale",
      "electronics"
    ],
  };

  String? selectedMainGroup;
  String? selectedCollection;
  String? selectedPlaceId;
  String? selectedPlaceName;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedPlaceId == null) {
      AppSnackBar.show(context, "يرجى تعبئة جميع الحقول واختيار المكان",
          backgroundColor: Colors.orange, icon: Icons.error);
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection("offerRequests").add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': _imageUrlController.text.trim(), // 👈 رابط URL
        'placeId': selectedPlaceId,
        'placeName': selectedPlaceName,
        'placeType': selectedCollection,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppSnackBar.show(
        context,
        'تم إرسال الطلب بانتظار موافقة الأدمن',
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );

      Navigator.of(context).pop();
    } catch (e) {
      AppSnackBar.show(
        context,
        'حدث خطأ أثناء إرسال الطلب',
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.error,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _extractName(Map<String, dynamic> data) {
    if ((data['name'] ?? '').toString().isNotEmpty) return data['name'];
    if ((data['title'] ?? '').toString().isNotEmpty) return data['title'];
    return "بدون اسم";
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلب عرض جديد')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'عنوان العرض'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'الرجاء إدخال العنوان' : null,
                ),
                const SizedBox(height: 12),

                // Dropdown المجموعات الرئيسية
                DropdownButtonFormField<String>(
                  value: selectedMainGroup,
                  decoration: const InputDecoration(
                    labelText: "اختر المجموعة الرئيسية",
                    border: OutlineInputBorder(),
                  ),
                  items: mainCollections.keys.map((group) {
                    return DropdownMenuItem<String>(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedMainGroup = val;
                      selectedCollection = null;
                      selectedPlaceId = null;
                      selectedPlaceName = null;
                    });
                  },
                  validator: (val) =>
                  val == null ? "يرجى اختيار المجموعة" : null,
                ),
                const SizedBox(height: 12),

                if (selectedMainGroup != null)
                  DropdownButtonFormField<String>(
                    value: selectedCollection,
                    decoration: const InputDecoration(
                      labelText: "اختر القسم",
                      border: OutlineInputBorder(),
                    ),
                    items: mainCollections[selectedMainGroup]!
                        .map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCollection = val;
                        selectedPlaceId = null;
                        selectedPlaceName = null;
                      });
                    },
                    validator: (val) =>
                    val == null ? "يرجى اختيار القسم" : null,
                  ),
                const SizedBox(height: 12),

                if (selectedCollection != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(selectedCollection!)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;

                      return DropdownButtonFormField<String>(
                        value: selectedPlaceId,
                        decoration: const InputDecoration(
                          labelText: "اختر المكان",
                          border: OutlineInputBorder(),
                        ),
                        items: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: d.id,
                            child: Text(_extractName(data)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final doc = docs.firstWhere((e) => e.id == val);
                          final data = doc.data() as Map<String, dynamic>;
                          setState(() {
                            selectedPlaceId = doc.id;
                            selectedPlaceName = _extractName(data);
                          });
                        },
                        validator: (val) =>
                        val == null ? "يرجى اختيار المكان" : null,
                      );
                    },
                  ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  decoration:
                  const InputDecoration(labelText: 'وصف العرض'),
                  maxLines: 4,
                  validator: (v) =>
                  v == null || v.isEmpty ? 'الرجاء إدخال الوصف' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: "رابط الصورة (URL)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) => (v == null || v.isEmpty)
                      ? "يرجى إدخال رابط الصورة"
                      : null,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال العرض'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
