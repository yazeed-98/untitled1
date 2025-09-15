import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled1/regesterUser/LOginScreen.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen(),)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "تسجيل الخروج",
      icon: const Icon(Icons.logout),
      onPressed: () => _logout(context),
    );
  }
}
