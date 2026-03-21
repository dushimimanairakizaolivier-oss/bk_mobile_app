import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/ai_assistant_overlay.dart';
import 'dashboard_screen.dart';
import 'services_screen.dart';
import 'profile_screen.dart';
import 'user/user_loans_screen.dart';
import 'admin/admin_dashboard_screen.dart' as admin_dash;
import 'admin/user_management_screen.dart' as admin_users;
import 'admin/loan_approvals_screen.dart' as admin_loans;
import 'admin/audit_logs_screen.dart' as admin_logs;
import 'admin/admin_actions_screen.dart' as admin_actions;

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _userScreens = [
    const DashboardScreen(),
    const UserLoansScreen(),
    const ServicesScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _adminScreens = [
    const admin_dash.AdminDashboardScreen(),
    const admin_users.UserManagementScreen(),
    const admin_loans.LoanApprovalsScreen(),
    const admin_actions.AdminActionsScreen(),
    const admin_logs.AuditLogsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';
    final screens = isAdmin ? _adminScreens : _userScreens;

    // Ensure _currentIndex is valid when switching roles
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    final userNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Loans'),
      BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Services'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    final adminNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
      BottomNavigationBarItem(icon: Icon(Icons.request_page), label: 'Loans'),
      BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Bank'),
      // BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Logs'),
    ];

    final navItems = isAdmin ? adminNavItems : userNavItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BK Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            // Tablet / Desktop layout with NavigationRail
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(
                    color: Theme.of(context).primaryColor,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: navItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          label: Text(item.label ?? ''),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: screens[_currentIndex]),
              ],
            );
          } else {
            // Mobile layout
            return screens[_currentIndex];
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              items: navItems,
            )
          : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AiAssistantOverlay(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
    );
  }
}
