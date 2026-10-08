import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
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

  Future<void> _printOrExportBadge(
    BuildContext context,
    String churchName,
    String schoolTitle,
  ) async {
    final pdf = pw.Document();
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    final qrPayload = QRCodeService.generatePayload(student.id);
    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final photoBytes = _photoBytes;

    final safeChurchName = churchName.trim().isEmpty
        ? 'اسم الكنيسة'
        : churchName.trim();
    final safeSchoolTitle = schoolTitle.trim().isEmpty
        ? 'مدرسة الشمامسة'
        : schoolTitle.trim();
    final safeStudentName = student.name.trim().isEmpty
        ? 'اسم الشماس'
        : student.name.trim();
    final servantName = currentUser?.fullName.trim().isNotEmpty == true
        ? currentUser!.fullName.trim()
        : 'الخادم';
    final safeGrade = student.grade.trim().isEmpty
        ? 'غير محدد'
        : student.grade.trim();
    final shortId = student.id.length > 8
        ? student.id.substring(0, 8)
        : student.id;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(200, 320, marginAll: 8),
        build: (pw.Context ctx) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.amber800, width: 2.5),
                gradient: const pw.LinearGradient(
                  colors: [PdfColors.red900, PdfColor.fromInt(0xFF1A0A2E)],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      safeChurchName,
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.red900,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    safeSchoolTitle,
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      color: PdfColors.amber200,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(height: 1, color: PdfColors.amber),
                  pw.SizedBox(height: 8),

                  // صورة الشماس
                  pw.Container(
                    width: 70,
                    height: 70,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.amber, width: 2),
                      color: PdfColor.fromInt(0x3DFFFFFF),
                    ),
                    alignment: pw.Alignment.center,
                    child: photoBytes != null
                        ? pw.ClipOval(
                            child: pw.Image(
                              pw.MemoryImage(photoBytes),
                              width: 66,
                              height: 66,
                              fit: pw.BoxFit.cover,
                            ),
                          )
                        : pw.Center(
                            child: pw.Text(
                              'صورة',
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 10,
                                color: PdfColors.amber200,
                              ),
                            ),
                          ),
                  ),
                  pw.SizedBox(height: 8),

                  pw.Text(
                    'اسم الشماس',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8,
                      color: PdfColor.fromInt(0xB3FFFFFF),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    safeStudentName,
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'المرحلة: $safeGrade',
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.red900,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrPayload,
                      width: 92,
                      height: 92,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'كود الشماس: $shortId',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8,
                      color: PdfColor.fromInt(0xB3FFFFFF),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'الخادم: $servantName',
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7,
                      color: PdfColors.amber200,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'كارنيه_${student.name.replaceAll(RegExp(r'\s+'), '_')}.pdf',
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
        : 'الخادم';
    final shortId = student.id.length > 8
        ? student.id.substring(0, 8)
        : student.id;
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
            tooltip: 'طباعة الكارنيه',
            onPressed: () => _printOrExportBadge(
              context,
              settings.churchName,
              settings.schoolTitle,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final cardWidth = availableWidth < 360 ? availableWidth - 12 : 340.0;
          final qrSize = availableWidth < 360 ? 76.0 : 90.0;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cardWidth.clamp(260.0, 340.0),
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(
                          color: AppTheme.copticGold,
                          width: 3,
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.church,
                                  color: AppTheme.copticGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        churchName,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
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
                                          fontSize: 14,
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
                                  size: 20,
                                ),
                              ],
                            ),
                            const Divider(
                              color: AppTheme.copticGold,
                              thickness: 1.5,
                              height: 18,
                            ),
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
                                radius: 44,
                                backgroundColor: Colors.white24,
                                backgroundImage: photoBytes != null
                                    ? MemoryImage(photoBytes)
                                    : null,
                                child: photoBytes == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: AppTheme.copticGold,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              studentName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 260),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
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
                              child: QrImageView(
                                data: qrPayload,
                                version: QrVersions.auto,
                                size: qrSize,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: AppTheme.primaryDarkBurgundy,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: AppTheme.primaryDarkBurgundy,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'كود الشماس: $shortId',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _printOrExportBadge(
                          context,
                          settings.churchName,
                          settings.schoolTitle,
                        ),
                        icon: const Icon(Icons.print, size: 22),
                        label: Text(
                          'طباعة الكارنيه / PDF',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBurgundy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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
