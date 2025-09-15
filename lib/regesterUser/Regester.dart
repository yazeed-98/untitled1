import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../clasess/app_snackbar.dart';
import 'LOginScreen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _submitting = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    AppSnackBar.show(
      context,
      'جاري إنشاء الحساب...',
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: Icons.hourglass_bottom,
    );

    UserCredential? cred;

    try {
      final fullName   = _fullNameController.text.trim();
      final nationalId = _nationalIdController.text.trim();
      final age        = int.parse(_ageController.text.trim());
      final email      = _emailController.text.trim();
      final pass       = _passController.text;

      // 1) إنشاء الحساب
      cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      await cred.user?.updateDisplayName(fullName);

      // 2) حفظ البيانات في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'fullName': fullName,
        'nationalId': nationalId,
        'age': age,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      AppSnackBar.show(
        context,
        'تم تسجيل المستخدم بنجاح',
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'فشل إنشاء الحساب';
      if (e.code == 'email-already-in-use') msg = 'هذا البريد مستخدم مسبقًا';
      if (e.code == 'invalid-email') msg = 'بريد إلكتروني غير صالح';
      if (e.code == 'weak-password') msg = 'كلمة المرور ضعيفة (6 أحرف على الأقل)';

      AppSnackBar.show(
        context,
        msg,
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        'خطأ غير متوقع: $e',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      try { await cred?.user?.delete(); } catch (_) {}
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تسجيل مستخدم جديد"),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      // باقي الحقول زي ما عندك بدون تغيير ...

                      const SizedBox(height: 24),

                      // زر التسجيل
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Text("تسجيل"),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('عندي حساب؟'),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text('تسجيل الدخول'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
