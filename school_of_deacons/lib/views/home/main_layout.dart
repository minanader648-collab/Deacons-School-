import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import '../students/student_list_screen.dart';
import '../attendance/qr_scanner_screen.dart';
import '../reports/monthly_report_screen.dart';
import '../settings/church_settings_screen.dart';
import '../settings/pending_servants_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    StudentListScreen(),
    QRScannerScreen(),
    MonthlyReportScreen(),
    ChurchSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.churchName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.copticAccentGold,
              ),
            ),
            Text(
              settings.schoolTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (authProvider.isAdmin)
            IconButton(
              icon: Badge(
                isLabelVisible: authProvider.pendingCount > 0,
                label: Text('${authProvider.pendingCount}'),
                child: const Icon(Icons.how_to_reg, color: AppTheme.copticGold),
              ),
              tooltip: 'موافقة الخدام',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingServantsScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.copticGold, size: 26),
            tooltip: 'مسح QR جديد',
            onPressed: () {
              setState(() {
                _selectedIndex = 2;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
              } else if (value == 'settings') {
                setState(() {
                  _selectedIndex = 4;
                });
              } else if (value == 'approvals') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingServantsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  'مرحباً: ${currentUser?.fullName ?? "الخادم"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBurgundy,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              if (authProvider.isAdmin)
                PopupMenuItem(
                  value: 'approvals',
                  child: Row(
                    children: [
                      const Icon(Icons.how_to_reg, color: AppTheme.primaryBurgundy),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'موافقة الخدام (${authProvider.pendingCount})',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: AppTheme.primaryBurgundy),
                    const SizedBox(width: 8),
                    Text('إعدادات الكنيسة', style: GoogleFonts.cairo()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Desktop Navigation Rail / Sidebar
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  backgroundColor: AppTheme.copticNavy,
                  selectedIconTheme: const IconThemeData(color: AppTheme.copticGold, size: 28),
                  unselectedIconTheme: const IconThemeData(color: Colors.white60, size: 24),
                  selectedLabelTextStyle: GoogleFonts.cairo(
                    color: AppTheme.copticGold,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: GoogleFonts.cairo(
                    color: Colors.white60,
                  ),
                  extended: true,
                  leading: Column(
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        backgroundColor: AppTheme.primaryBurgundy,
                        radius: 28,
                        child: Icon(Icons.church, color: AppTheme.copticGold, size: 30),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('الرئيسية'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('المخدومين'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.qr_code_scanner),
                      selectedIcon: Icon(Icons.qr_code_scanner_outlined),
                      label: Text('مسح QR'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.table_chart_outlined),
                      selectedIcon: Icon(Icons.table_chart),
                      label: Text('تقرير إكسيل'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('الإعدادات'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _pages[_selectedIndex]),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppTheme.primaryBurgundy,
              selectedItemColor: AppTheme.copticGold,
              unselectedItemColor: Colors.white70,
              selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.cairo(),
              selectedFontSize: 11,
              unselectedFontSize: 10,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.badge_outlined),
                  label: 'المخدومين',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner, size: 28),
                  label: 'مسح QR',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.table_chart),
                  label: 'إكسيل',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'الإعدادات',
                ),
              ],
            ),
    );
  }
}
