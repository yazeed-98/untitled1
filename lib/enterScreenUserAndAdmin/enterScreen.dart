import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // شعار "ثقة"
              Text(
                'ثقة',
                style: GoogleFonts.cairo(
                  textStyle: textTheme.headlineLarge?.copyWith(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // الشعار الفرعي
              Text(
                'وثّق إعلانك',
                style: GoogleFonts.cairo(
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // أنيميشن "صح ✅"
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  Icons.check_circle,
                  size: size.width * 0.45, // متناسب مع الشاشة
                  color: colorScheme.primary,
                ),
              ),

              const Spacer(),

              // زر الدخول
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/login"); // أو أي صفحة
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ابدأ الآن',
                        style: GoogleFonts.cairo(
                          textStyle: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_ios, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
