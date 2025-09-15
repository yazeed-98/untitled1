import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../clasess/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class NewOfferRequestPage extends StatefulWidget {
  const NewOfferRequestPage({super.key});

  @override
  State<NewOfferRequestPage> createState() => _NewOfferRequestPageState();
}

class _NewOfferRequestPageState extends State<NewOfferRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _placeNameController = TextEditingController();
  File? _image;

  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? imageUrl;
      if (_image != null) {
        // رفع الصورة على Firebase Storage (مطلوب إعداد Storage مسبق)
        // هنا مجرد مثال placeholder
        imageUrl = 'https://via.placeholder.com/200x120.png?text=Image';
      }

      await FirebaseFirestore.instance.collection('offerRequests').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'placeName': _placeNameController.text.trim(),
        'image': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppSnackBar.show(
        context,
        'تم إرسال الطلب بنجاح!',
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلب إعلان جديد')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الإعلان',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال العنوان' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _placeNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المطعم / المكان (اختياري)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'وصف الإعلان',
                  ),
                  maxLines: 4,
                  validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال الوصف' : null,
                ),
                const SizedBox(height: 12),
                if (_image != null)
                  Image.file(_image!, height: 150, fit: BoxFit.cover),
                TextButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('اختر صورة (اختياري)'),
                  onPressed: _pickImage,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال الطلب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
