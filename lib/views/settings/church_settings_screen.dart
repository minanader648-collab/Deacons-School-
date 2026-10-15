import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'pending_servants_screen.dart';

class ChurchSettingsScreen extends StatefulWidget {
  const ChurchSettingsScreen({super.key});

  @override
  State<ChurchSettingsScreen> createState() => _ChurchSettingsScreenState();
}

class _ChurchSettingsScreenState extends State<ChurchSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _churchNameController = TextEditingController();
  final _schoolTitleController = TextEditingController();
  final _deaconRankController = TextEditingController();
  final _newGradeController = TextEditingController();
  List<String> _grades = [];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    _churchNameController.text = settings.churchName;
    _schoolTitleController.text = settings.schoolTitle;
    _deaconRankController.text = settings.deaconRankTitle;
    _grades = List.from(settings.grades);
  }

  @override
  void dispose() {
    _churchNameController.dispose();
    _schoolTitleController.dispose();
    _deaconRankController.dispose();
    _newGradeController.dispose();
    super.dispose();
  }

  void _addGrade() {
    final newGrade = _newGradeController.text.trim();
    if (newGrade.isNotEmpty && !_grades.contains(newGrade)) {
      setState(() {
        _grades.add(newGrade);
        _newGradeController.clear();
      });
    }
  }

  void _removeGrade(String grade) {
    setState(() {
      _grades.remove(grade);
    });
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      await settingsProvider.updateSettings(
        churchName: _churchNameController.text.trim(),
        schoolTitle: _schoolTitleController.text.trim(),
        deaconRankTitle: _deaconRankController.text.trim(),
        grades: _grades,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ إعدادات الكنيسة والخدمة بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إعدادات الكنيسة والخدمة',
          style: GoogleFonts.cairo(color: AppTheme.copticGold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (auth.isAdmin) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.copticGold, width: 1),
                      ),
                      child: ListTile(
                        leading: Badge(
                          isLabelVisible: auth.pendingCount > 0,
                          label: Text('${auth.pendingCount}'),
                          child: const Icon(Icons.how_to_reg, color: AppTheme.primaryBurgundy),
                        ),
                        title: Text(
                          'موافقة الخدام الجدد',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          auth.pendingCount > 0
                              ? '${auth.pendingCount} طلب بانتظار الموافقة'
                              : 'لا توجد طلبات معلقة',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PendingServantsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppTheme.copticGold, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اسم الكنيسة وبيانات الخدمة',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBurgundy,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Church Name (اسم الكنيسة)
                          TextFormField(
                            controller: _churchNameController,
                            decoration: const InputDecoration(
                              labelText: 'اسم الكنيسة (مثال: كنيسة الشهيد العظيم مارجرجس)',
                              prefixIcon: Icon(Icons.church, color: AppTheme.primaryBurgundy),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال اسم الكنيسة';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Service / School Title
                          TextFormField(
                            controller: _schoolTitleController,
                            decoration: const InputDecoration(
                              labelText: 'اسم الخدمة (مثال: خدمة مدرسة الشمامسة)',
                              prefixIcon: Icon(Icons.school, color: AppTheme.primaryBurgundy),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال اسم الخدمة';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Deacon Rank Title
                          TextFormField(
                            controller: _deaconRankController,
                            decoration: const InputDecoration(
                              labelText: 'عنوان رتب الشمامسة / الكارنيه',
                              prefixIcon: Icon(Icons.badge, color: AppTheme.primaryBurgundy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grades / Academic Levels Management Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المراحل / السنوات الدراسية',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBurgundy,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newGradeController,
                                  decoration: const InputDecoration(
                                    hintText: 'إضافة مرحلة جديدة...',
                                    prefixIcon: Icon(Icons.add_location_alt_outlined, color: AppTheme.primaryBurgundy),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBurgundy,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                onPressed: _addGrade,
                                child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _grades.map((grade) {
                              return Chip(
                                backgroundColor: AppTheme.primaryBurgundy.withValues(alpha: 0.1),
                                label: Text(grade, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.primaryDarkBurgundy)),
                                deleteIcon: const Icon(Icons.close, size: 18, color: Colors.red),
                                onDeleted: () => _removeGrade(grade),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save, size: 24),
                      label: Text('حفظ إعدادات الكنيسة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBurgundy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
