import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../home/main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final String _fullTitle = 'مدرسة صفوف السمائيين بشرم الشيخ';
  String _displayedTitle = '';
  int _charIndex = 0;
  Timer? _typewriterTimer;
  Timer? _navTimer;

  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showSubtitle = false;

  @override
  void initState() {
    super.initState();

    // أنيميشن ظهور وتكبير اللوجو بسلاسة
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _logoController.forward();

    // بدء كتابة النص حرفاً بحرف (Typewriter Effect)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _startTypewriter();
    });
  }

  void _startTypewriter() {
    // سرعة ظهور الحروف (حرف كل 65 مللي ثانية)
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex < _fullTitle.length) {
        setState(() {
          _charIndex++;
          _displayedTitle = _fullTitle.substring(0, _charIndex);
        });
      } else {
        timer.cancel();
        setState(() {
          _showSubtitle = true;
        });

        // الانتقال التلقائي بعد الانتهاء
        _navTimer = Timer(const Duration(milliseconds: 1400), () {
          _navigateToNextScreen();
        });
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) {
          return authProvider.isAuthenticated
              ? const MainLayout()
              : const LoginScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _navTimer?.cancel();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        onTap: _navigateToNextScreen, // إمكانية التخطي بالضغط في أي مكان
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryDarkBurgundy,
                AppTheme.primaryBurgundy,
                AppTheme.copticNavy,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- اللوجو الملكي مع الإطار المذهب والتوهج ---
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.copticGold.withValues(alpha: 0.4),
                                      blurRadius: 30,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AppTheme.copticGold,
                                    width: 3.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const CircleAvatar(
                                        backgroundColor: AppTheme.primaryDarkBurgundy,
                                        child: Icon(
                                          Icons.church,
                                          color: AppTheme.copticGold,
                                          size: 80,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // --- النص الذي يظهر حرفاً بحرف ---
                          Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            alignment: Alignment.center,
                            child: Text(
                              _displayedTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.copticAccentGold,
                                letterSpacing: 0.5,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // --- التذييل الكنسي الذي يظهر بعد انتهاء الكتابة ---
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            opacity: _showSubtitle ? 1.0 : 0.0,
                            child: Text(
                              '+ بركة صلوات الآباء والقديسين +',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // زر تخطي في الأسفل
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'اضغط للمتابعة',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
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
