import 'dart:convert';

class ChurchSettings {
  final String churchName;
  final String schoolTitle;
  final String deaconRankTitle;
  final List<String> grades;
  final String logoBase64;
  final bool isFirebaseEnabled;

  ChurchSettings({
    this.churchName = 'كنيسة الشهيد العظيم مارجرجس',
    this.schoolTitle = 'خدمة مدرسة الشمامسة',
    this.deaconRankTitle = 'مدرسة الشمامسة',
    List<String>? grades,
    this.logoBase64 = '',
    this.isFirebaseEnabled = false,
  }) : grades = grades ??
            const [
              'أولى إبتدائي',
              'ثانية إبتدائي',
              'ثالثة إبتدائي',
              'رابعة إبتدائي',
              'خامسة إبتدائي',
              'سادسة إبتدائي',
              'مرحلة إعدادي',
              'مرحلة ثانوي',
              'مرحلة خريجين / كبار',
            ];

  Map<String, dynamic> toMap() {
    return {
      'churchName': churchName,
      'schoolTitle': schoolTitle,
      'deaconRankTitle': deaconRankTitle,
      'grades': grades,
      'logoBase64': logoBase64,
      'isFirebaseEnabled': isFirebaseEnabled,
    };
  }

  factory ChurchSettings.fromMap(Map<String, dynamic> map) {
    return ChurchSettings(
      churchName: map['churchName'] ?? 'كنيسة الشهيد العظيم مارجرجس',
      schoolTitle: map['schoolTitle'] ?? 'خدمة مدرسة الشمامسة',
      deaconRankTitle: map['deaconRankTitle'] ?? 'مدرسة الشمامسة',
      grades: map['grades'] != null ? List<String>.from(map['grades']) : null,
      logoBase64: map['logoBase64'] ?? '',
      isFirebaseEnabled: map['isFirebaseEnabled'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChurchSettings.fromJson(String source) =>
      ChurchSettings.fromMap(json.decode(source));

  ChurchSettings copyWith({
    String? churchName,
    String? schoolTitle,
    String? deaconRankTitle,
    List<String>? grades,
    String? logoBase64,
    bool? isFirebaseEnabled,
  }) {
    return ChurchSettings(
      churchName: churchName ?? this.churchName,
      schoolTitle: schoolTitle ?? this.schoolTitle,
      deaconRankTitle: deaconRankTitle ?? this.deaconRankTitle,
      grades: grades ?? this.grades,
      logoBase64: logoBase64 ?? this.logoBase64,
      isFirebaseEnabled: isFirebaseEnabled ?? this.isFirebaseEnabled,
    );
  }
}
