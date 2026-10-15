import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/badge_pdf_service.dart';
import '../../services/qr_code_service.dart';
import '../../theme/app_theme.dart';

class StudentBadgeScreen extends StatelessWidget {
  final Student student;
  const StudentBadgeScreen({super.key, required this.student});

  bool get _hasPhoto =>
      student.photoBase64 != null && student.photoBase64!.isNotEmpty;

  Uint8List? get _photoBytes {
    if (!_hasPhoto) return null;
    try {
      return base64Decode(student.photoBase64!);
    } catch (_) {
      return null;
    }
  }

  void _printSingleBadge(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    BadgePdfService.printSingleBadge(
      context: context,
      student: student,
      settings: settings,
      servantName: currentUser?.fullName,
    );
  }

  void _printAllBadges(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    final students = Provider.of<StudentProvider>(context, listen: false).students;
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    BadgePdfService.printBatchBadges(
      context: context,
      students: students,
      settings: settings,
      servantName: currentUser?.fullName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final qrPayload = QRCodeService.generatePayload(student.id);
    final churchName = settings.churchName.trim().isEmpty
        ? 'اسم الكنيسة'
        : settings.churchName.trim();
    final schoolTitle = settings.schoolTitle.trim().isEmpty
        ? 'مدرسة الشمامسة'
        : settings.schoolTitle.trim();
    final studentName = student.name.trim().isEmpty
        ? 'اسم الشماس'
        : student.name.trim();
    final servantName =
        authProvider.currentUser?.fullName.trim().isNotEmpty == true
            ? authProvider.currentUser!.fullName.trim()
            : 'الخادم المسؤول';
    final shortId = student.id.length > 8
        ? student.id.substring(0, 8).toUpperCase()
        : student.id.toUpperCase();
    final photoBytes = _photoBytes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'كارنيه الشماس الذكي',
          style: GoogleFonts.cairo(color: AppTheme.copticGold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppTheme.copticGold),
            tooltip: 'طباعة هذا الكارنيه',
            onPressed: () => _printSingleBadge(context),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            tooltip: 'طباعة كل الكارنيهات في ملف واحد',
            onPressed: () => _printAllBadges(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final cardWidth = availableWidth < 380 ? availableWidth - 24 : 350.0;
          final qrSize = availableWidth < 380 ? 95.0 : 110.0;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // بطاقة معاينة الكارنيه
                  SizedBox(
                    width: cardWidth.clamp(280.0, 360.0),
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(
                          color: AppTheme.copticGold,
                          width: 2.5,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryDarkBurgundy,
                              AppTheme.primaryBurgundy,
                              AppTheme.copticNavy,
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // الترويسة
                            Row(
                              children: [
                                const Icon(
                                  Icons.church,
                                  color: AppTheme.copticGold,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        churchName,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: AppTheme.copticAccentGold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        schoolTitle,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.church,
                                  color: AppTheme.copticGold,
                                  size: 22,
                                ),
                              ],
                            ),
                            const Divider(
                              color: AppTheme.copticGold,
                              thickness: 1.5,
                              height: 18,
                            ),

                            // صورة الشماس
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.copticGold,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.white24,
                                backgroundImage: photoBytes != null
                                    ? MemoryImage(photoBytes)
                                    : null,
                                child: photoBytes == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppTheme.copticGold,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // اسم الشماس
                            Text(
                              studentName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // شارة المرحلة
                            Container(
                              constraints: const BoxConstraints(maxWidth: 260),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.copticGold,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'المرحلة: ${student.grade}',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDarkBurgundy,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // كود الـ QR عالي الوضوح
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  QrImageView(
                                    data: qrPayload,
                                    version: QrVersions.auto,
                                    size: qrSize,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'امسح لتسجيل الحضور',
                                    style: GoogleFonts.cairo(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBurgundy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // كود الشماس واسم الخادم
                            Text(
                              'كود الشماس: #$shortId',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الخادم: $servantName',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: AppTheme.copticAccentGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // أزرار الطباعة
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _printSingleBadge(context),
                            icon: const Icon(Icons.print, size: 22),
                            label: Text(
                              'طباعة هذا الكارنيه (PDF)',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBurgundy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _printAllBadges(context),
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: AppTheme.primaryBurgundy,
                              size: 22,
                            ),
                            label: Text(
                              'طباعة كل الكارنيهات في ملف واحد (A4)',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBurgundy,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.primaryBurgundy,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
