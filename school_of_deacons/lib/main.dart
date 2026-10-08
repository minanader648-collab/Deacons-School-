import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'views/auth/login_screen.dart';
import 'views/home/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Local-storage fallback when Firebase isn't available on this platform
    debugPrint('Firebase initialisation fallback: $e');
  }

  runApp(const DeaconSchoolApp());
}

class DeaconSchoolApp extends StatelessWidget {
  const DeaconSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'مدرسة الشمامسة',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(context),
            darkTheme: AppTheme.darkTheme(context),
            themeMode: ThemeMode.system,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
            home: authProvider.isLoading
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBurgundy,
                      ),
                    ),
                  )
                : authProvider.isAuthenticated
                    ? const MainLayout()
                    : const LoginScreen(),
          );
        },
      ),
    );
  }
}
