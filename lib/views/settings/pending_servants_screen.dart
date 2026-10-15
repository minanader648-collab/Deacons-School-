import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class PendingServantsScreen extends StatefulWidget {
  const PendingServantsScreen({super.key});

  @override
  State<PendingServantsScreen> createState() => _PendingServantsScreenState();
}

class _PendingServantsScreenState extends State<PendingServantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshServantsList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pending = auth.pendingServants;
    final all = auth.allServants;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'موافقة الخدام',
          style: GoogleFonts.cairo(color: AppTheme.copticGold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshServantsList(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'طلبات بانتظار الموافقة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBurgundy,
              ),
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'لا توجد طلبات معلقة حالياً',
                      style: GoogleFonts.cairo(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              )
            else
              ...pending.map((servant) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servant.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          servant.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'تاريخ الطلب: ${DateFormat('yyyy/MM/dd HH:mm').format(servant.createdAt)}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final ok = await auth.approveServant(servant.email);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'تم قبول ${servant.fullName}'
                                              : (auth.errorMessage ?? 'فشل القبول'),
                                          style: GoogleFonts.cairo(),
                                        ),
                                        backgroundColor:
                                            ok ? Colors.green.shade700 : Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check, size: 18),
                                label: Text('قبول', style: GoogleFonts.cairo()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final ok = await auth.rejectServant(servant.email);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'تم رفض ${servant.fullName}'
                                              : (auth.errorMessage ?? 'فشل الرفض'),
                                          style: GoogleFonts.cairo(),
                                        ),
                                        backgroundColor:
                                            ok ? Colors.orange.shade800 : Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                label: Text(
                                  'رفض',
                                  style: GoogleFonts.cairo(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text(
              'كل الخدام',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBurgundy,
              ),
            ),
            const SizedBox(height: 8),
            ...all.map((servant) {
              Color statusColor;
              String statusLabel;
              switch (servant.approvalStatus) {
                case 'approved':
                  statusColor = Colors.green;
                  statusLabel = 'مقبول';
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  statusLabel = 'مرفوض';
                  break;
                default:
                  statusColor = Colors.orange;
                  statusLabel = 'قيد الانتظار';
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBurgundy.withValues(alpha: 0.15),
                    child: Icon(
                      servant.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: AppTheme.primaryBurgundy,
                    ),
                  ),
                  title: Text(
                    servant.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${servant.email}${servant.isAdmin ? ' • أمين الخدمة' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text(
                      statusLabel,
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: statusColor,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
