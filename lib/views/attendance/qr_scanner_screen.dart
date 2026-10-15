import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/qr_code_service.dart';
import '../../theme/app_theme.dart';
import 'manual_attendance_screen.dart';
import 'today_attendance_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _processScannedCode(rawValue);
        break;
      }
    }
  }

  void _processScannedCode(String scannedData) async {
    setState(() => _isProcessing = true);

    final studentId = QRCodeService.extractStudentId(scannedData);
    if (studentId == null || studentId.isEmpty) {
      _showFeedback(
        title: 'رمز QR غير صالح',
        message: 'الرمز الممسوح لا يطابق نظام كود مدرسة الشمامسة',
        isSuccess: false,
      );
      return;
    }

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final student = studentProvider.getStudentById(studentId);
    if (student == null) {
      _showFeedback(
        title: 'المخدوم غير موجود',
        message: 'كود المخدوم غير مسجل في قاعدة البيانات',
        isSuccess: false,
      );
      return;
    }

    final alreadyPresent = attendanceProvider.isPresentToday(student.id);
    if (alreadyPresent) {
      _showFeedback(
        title: 'تم التسجيل مسبقاً ⚠️',
        message: 'المخدوم: ${student.name}\nالمرحلة: ${student.grade}\nتم تسجيل حضوره بالفعل اليوم.',
        isSuccess: false,
        studentName: student.name,
        photoBase64: student.photoBase64,
        allowDelete: true,
        studentId: student.id,
        onDelete: () async {
          await attendanceProvider.deleteAttendanceForStudent(
            studentId: student.id,
            date: DateTime.now(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم مسح حضور ${student.name} من اليوم', style: GoogleFonts.cairo()),
                backgroundColor: Colors.orange.shade700,
              ),
            );
          }
        },
      );
      return;
    }

    final servantName = authProvider.currentUser?.fullName ?? 'الخادم';
    await attendanceProvider.recordAttendance(
      student: student,
      recordedBy: servantName,
    );

    _showFeedback(
      title: 'تم تسجيل الحضور بنجاح! ✓',
      message: 'أهلاً بك يا شماس: ${student.name}\nالمرحلة الدراسية: ${student.grade}',
      isSuccess: true,
      studentName: student.name,
      photoBase64: student.photoBase64,
    );
  }

  void _showFeedback({
    required String title,
    required String message,
    required bool isSuccess,
    String? studentName,
    String? photoBase64,
    bool allowDelete = false,
    String? studentId,
    VoidCallback? onDelete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isSuccess ? Colors.green.shade700 : AppTheme.primaryBurgundy,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoBase64 != null && photoBase64.isNotEmpty)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: MemoryImage(base64Decode(photoBase64)),
                )
              else
                CircleAvatar(
                  radius: 36,
                  backgroundColor: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    size: 48,
                    color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green.shade800 : AppTheme.primaryBurgundy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14),
              ),
              const SizedBox(height: 18),

              // --- زر المتابعة ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green.shade700 : AppTheme.primaryBurgundy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'متابعة المسح الضوئي',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() => _isProcessing = false);
                  },
                ),
              ),

              // --- زر مسح الحضور (فقط عند التكرار) ---
              if (allowDelete && onDelete != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                    label: Text(
                      'مسح من حضور اليوم',
                      style: GoogleFonts.cairo(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      setState(() => _isProcessing = false);
                      onDelete();
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ماسح الـ QR وتسجيل الحضور',
          style: GoogleFonts.cairo(color: AppTheme.copticGold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt, color: AppTheme.copticGold),
            tooltip: 'حضور اليوم',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TodayAttendanceScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_check, color: AppTheme.copticGold),
            tooltip: 'كشف الحضور اليدوي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualAttendanceScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // --- الكاميرا ---
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppTheme.copticGold, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'وجه الكاميرا نحو كارنيه المخدوم',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBurgundy,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.flash_on, color: AppTheme.copticGold),
                                    onPressed: () => _cameraController.toggleTorch(),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cameraswitch, color: AppTheme.copticGold),
                                    onPressed: () => _cameraController.switchCamera(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 260,
                              width: double.infinity,
                              child: MobileScanner(
                                controller: _cameraController,
                                onDetect: _onDetect,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- إدخال يدوي ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أو ادخل كود الكارنيه (قارئ باركود USB)',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkBurgundy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _manualCodeController,
                                  decoration: const InputDecoration(
                                    hintText: 'ادخل كود الكارنيه يدويًا...',
                                    prefixIcon: Icon(Icons.qr_code, color: AppTheme.primaryBurgundy),
                                    isDense: true,
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      _processScannedCode(val.trim());
                                      _manualCodeController.clear();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBurgundy,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                ),
                                child: Text('تسجيل', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  if (_manualCodeController.text.trim().isNotEmpty) {
                                    _processScannedCode(_manualCodeController.text.trim());
                                    _manualCodeController.clear();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
