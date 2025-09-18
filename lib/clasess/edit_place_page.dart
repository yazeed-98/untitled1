import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditPlacePage extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> ref;

  const EditPlacePage({super.key, required this.ref});

  @override
  State<EditPlacePage> createState() => _EditPlacePageState();
}

class _EditPlacePageState extends State<EditPlacePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  bool _loading = true;
  String? _imageUrl;
  File? _pickedFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final snap = await widget.ref.get();
    if (snap.exists) {
      final data = snap.data()!;
      _nameCtrl.text = data['name'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _cityCtrl.text = data['city'] ?? '';
      _categoryCtrl.text = data['category'] ?? '';
      _imageUrlCtrl.text = data['image'] ?? '';
      _imageUrl = data['image'];
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedFile = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String finalImageUrl = _imageUrlCtrl.text.trim();

    // إذا المستخدم اختار صورة جديدة نرفعها
    if (_pickedFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('places/${widget.ref.id}.jpg');
      await storageRef.putFile(_pickedFile!);
      finalImageUrl = await storageRef.getDownloadURL();
    }

    await widget.ref.update({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'category': _categoryCtrl.text.trim(),
      'image': finalImageUrl,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ التعديلات ✅")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تعديل بيانات المكان"),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "اسم المكان",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? "مطلوب" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "الوصف",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "رقم الهاتف",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(
                    labelText: "المحافظة",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: "التصنيف",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // صورة
                if ((_pickedFile != null) || (_imageUrl?.isNotEmpty == true))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _pickedFile != null
                        ? Image.file(_pickedFile!, height: 160, fit: BoxFit.cover)
                        : Image.network(_imageUrl!, height: 160, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),

                // إدخال URL للصورة
                TextFormField(
                  controller: _imageUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: "رابط الصورة (URL)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("اختر صورة من الجهاز"),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text("حفظ"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
