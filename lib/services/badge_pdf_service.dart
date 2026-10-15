import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_model.dart';
import '../models/church_settings_model.dart';
import 'qr_code_service.dart';

class BadgePdfService {
  // Brand colors for PDF printing
  static const PdfColor primaryBurgundy = PdfColors.red900;
  static const PdfColor darkBurgundy = PdfColor.fromInt(0xFF4A121F);
  static const PdfColor copticGold = PdfColors.amber800;
  static const PdfColor goldLight = PdfColor.fromInt(0xFFFFF8E7);
  static const PdfColor goldBorder = PdfColors.amber700;

  /// Decodes base64 photo safely
  static Uint8List? _getPhotoBytes(String? base64Str) {
    if (base64Str == null || base64Str.trim().isEmpty) return null;
    try {
      return base64Decode(base64Str.trim());
    } catch (_) {
      return null;
    }
  }

  /// Builds a single badge widget for PDF
  static pw.Widget _buildBadgeCard({
    required Student student,
    required ChurchSettings settings,
    required String servantName,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    double cardWidth = 265,
    double cardHeight = 185,
    bool showCutBorder = true,
  }) {
    final qrPayload = QRCodeService.generatePayload(student.id);
    final photoBytes = _getPhotoBytes(student.photoBase64);

    final safeChurchName = settings.churchName.trim().isEmpty
        ? 'كنيسة الشهيد العظيم'
        : settings.churchName.trim();
    final safeSchoolTitle = settings.schoolTitle.trim().isEmpty
        ? 'مدرسة الشمامسة'
        : settings.schoolTitle.trim();
    final safeStudentName = student.name.trim().isEmpty
        ? 'اسم الشماس'
        : student.name.trim();
    final safeGrade = student.grade.trim().isEmpty
        ? 'غير محدد'
        : student.grade.trim();
    final shortId = student.id.length > 8
        ? student.id.substring(0, 8).toUpperCase()
        : student.id.toUpperCase();

    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      margin: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: showCutBorder
            ? pw.Border.all(
                color: PdfColors.grey400,
                width: 0.8,
                style: pw.BorderStyle.dashed,
              )
            : pw.Border.all(color: copticGold, width: 1.5),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 9,
        verticalRadius: 9,
        child: pw.Column(
          children: [
            // --- شريط الرأس: اسم الكنيسة ومدرسة الشمامسة ---
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const pw.BoxDecoration(
                color: primaryBurgundy,
                border: pw.Border(
                  bottom: pw.BorderSide(color: copticGold, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '+',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.amber,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          safeChurchName,
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.5,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          '$safeSchoolTitle - كارنيه عضوية',
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 7,
                            color: PdfColors.amber200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    '+',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.amber,
                    ),
                  ),
                ],
              ),
            ),

            // --- محتوى الكارنيه ---
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // عمود الصورة
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 50,
                          height: 50,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: goldBorder, width: 1.8),
                            color: goldLight,
                          ),
                          alignment: pw.Alignment.center,
                          child: photoBytes != null
                              ? pw.ClipOval(
                                  child: pw.Image(
                                    pw.MemoryImage(photoBytes),
                                    width: 48,
                                    height: 48,
                                    fit: pw.BoxFit.cover,
                                  ),
                                )
                              : pw.Center(
                                  child: pw.Text(
                                    'شماس',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 8,
                                      color: primaryBurgundy,
                                    ),
                                  ),
                                ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '#$shortId',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 6.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(width: 6),

                    // عمود بيانات الشماس
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            safeStudentName,
                            maxLines: 2,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10.5,
                              color: darkBurgundy,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: goldLight,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: goldBorder, width: 0.8),
                            ),
                            child: pw.Text(
                              'المرحلة: $safeGrade',
                              maxLines: 1,
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 7.5,
                                color: primaryBurgundy,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'الخادم: $servantName',
                            maxLines: 1,
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 6.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 4),

                    // عمود رمز الـ QR (أسود نقي عالي التباين للقراءة السريعة بالهاتف)
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.grey300, width: 1),
                          ),
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrPayload,
                            width: 58,
                            height: 58,
                            color: PdfColors.black, // أسود صريح لضمان سرعة المسح بالكاميرا
                            backgroundColor: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'امسح لتسجيل الحضور',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 5.5,
                            color: primaryBurgundy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- الشريط السفلي ---
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              decoration: const pw.BoxDecoration(
                color: goldLight,
                border: pw.Border(
                  top: pw.BorderSide(color: copticGold, width: 0.8),
                ),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '+ أذكرنا في صلواتك +',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 6.5,
                  color: darkBurgundy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// طباعة كل الكارنيهات في ملف PDF واحد (صفحات A4 مقسمة بحدود قص لسهولة الطباعة)
  static Future<void> printBatchBadges({
    required BuildContext context,
    required List<Student> students,
    required ChurchSettings settings,
    String? servantName,
    String? gradeFilter,
  }) async {
    if (students.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد مخدومين لطباعة كارنيهاتهم!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final safeServant = (servantName != null && servantName.trim().isNotEmpty)
        ? servantName.trim()
        : 'الخادم المسؤول';

    // كل صفحة A4 تحتوي على 8 كارنيهات (عمودين × 4 صفوف) بمقاس كارت قياسي
    const cardsPerPage = 8;
    final totalPages = (students.length / cardsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * cardsPerPage;
      final endIndex = (startIndex + cardsPerPage > students.length)
          ? students.length
          : startIndex + cardsPerPage;
      final pageStudents = students.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          build: (pw.Context ctx) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                children: [
                  // ترويسة صفحة الطباعة مع خط إرشادي للقص
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${settings.churchName} - ${settings.schoolTitle}',
                          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'كارنيهات الشمامسة (صفحة ${pageIndex + 1} من $totalPages)',
                          style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'قص بمحاذاة الخطوط المتقطعة',
                          style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  pw.SizedBox(height: 4),

                  // شبكة الكارنيهات (2 أعمدة × 4 صفوف)
                  pw.Expanded(
                    child: pw.Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: pw.WrapAlignment.center,
                      children: pageStudents.map((student) {
                        return _buildBadgeCard(
                          student: student,
                          settings: settings,
                          servantName: safeServant,
                          fontRegular: fontRegular,
                          fontBold: fontBold,
                          cardWidth: 268,
                          cardHeight: 184,
                          showCutBorder: true,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final fileTitle = gradeFilter != null && gradeFilter != 'الكل'
        ? 'كارنيهات_$gradeFilter.pdf'
        : 'كل_كارنيهات_الشمامسة.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileTitle,
    );
  }

  /// طباعة كارنيه فردي لمخدوم محدد بجودة عالية
  static Future<void> printSingleBadge({
    required BuildContext context,
    required Student student,
    required ChurchSettings settings,
    String? servantName,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final safeServant = (servantName != null && servantName.trim().isNotEmpty)
        ? servantName.trim()
        : 'الخادم';

    // صفحة A4 تحتوي الكارنيه في المنتصف مع علامات القص
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'كارنيه مدرسة الشمامسة الذكي',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: primaryBurgundy,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'قم بقص الكارنيه بمحاذاة الإطار الذهبي',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  _buildBadgeCard(
                    student: student,
                    settings: settings,
                    servantName: safeServant,
                    fontRegular: fontRegular,
                    fontBold: fontBold,
                    cardWidth: 320,
                    cardHeight: 215,
                    showCutBorder: false,
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'يمكن تغليف الكارنيه (Lamination) أو وضعه في حامل الكارنيه البلاستيكي',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8,
                      color: PdfColors.grey500,
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
}
