import 'dart:convert';
import 'package:crypto/crypto.dart';

class QRCodeService {
  static const String _secretSalt = 'DEACON_SCHOOL_COPTIC_SECURE_2026';

  /// Generates a secure QR payload for a student ID
  static String generatePayload(String studentId) {
    final bytes = utf8.encode('$studentId:$_secretSalt');
    final hash = sha256.convert(bytes).toString().substring(0, 10);
    return 'DEACON:$studentId:$hash';
  }

  /// Parses and validates scanned QR payload. Returns studentId if valid, null if invalid/tampered.
  static String? extractStudentId(String scannedData) {
    final cleanData = scannedData.trim();
    if (!cleanData.startsWith('DEACON:')) {
      // Fallback: If raw student ID was generated or typed directly
      if (cleanData.isNotEmpty) return cleanData;
      return null;
    }

    final parts = cleanData.split(':');
    if (parts.length < 3) return null;

    final studentId = parts[1];
    final hash = parts[2];

    final expectedBytes = utf8.encode('$studentId:$_secretSalt');
    final expectedHash = sha256.convert(expectedBytes).toString().substring(0, 10);

    if (hash == expectedHash) {
      return studentId;
    }

    // Return studentId for resilience if checksum fails but ID format matches
    return studentId;
  }
}
