import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import 'user_management_screen.dart';
import 'loan_approvals_screen.dart';
import 'audit_logs_screen.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final users = await api.getAllUsers();
  final loans = await api.getAdminLoans();
  
  return {
    'totalUsers': users.length,
    'pendingLoans': loans.where((l) => l.status == 'pending').length,
    'frozenAccounts': users.where((u) => u.status == 'frozen').length,
  };
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        actions: [
          IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Users',
                      value: stats['totalUsers'].toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Pending Loans',
                      value: stats['pendingLoans'].toString(),
                      icon: Icons.request_quote,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Frozen Accounts',
                      value: stats['frozenAccounts'].toString(),
                      icon: Icons.ac_unit,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
               error: (e, s) => Text('Error loading stats: $e'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Management Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _AdminToolCard(
              title: 'User Management',
              subtitle: 'View users, freeze accounts, create customers',
              icon: Icons.manage_accounts,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
            ),
            _AdminToolCard(
              title: 'Loan Approvals',
              subtitle: 'Review and approve pending loan requests',
              icon: Icons.check_circle_outline,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanApprovalsScreen())),
            ),
            // _AdminToolCard(
            //   title: 'Audit Logs',
            //   subtitle: 'View history of admin actions',
            //   icon: Icons.history,
            //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen())),
            // ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.withAlpha(200)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _AdminToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
