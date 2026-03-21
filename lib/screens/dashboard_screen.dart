import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import 'transfer_screen.dart';
import 'user/airtime_top_up_screen.dart' as user_airtime;
import 'user/pay_bills_screen.dart' as user_bills;
import 'user/fixed_deposit_screen.dart' as user_fd;
import '../models/notification.dart' as prefix_notif;

// Provider for fetching recent transactions
final recentTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.read(apiServiceProvider).getTransactions(user.id);
});

// Provider for fetching notifications
final notificationsProvider = FutureProvider<List<prefix_notif.Notification>>((
  ref,
) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.read(apiServiceProvider).getNotifications(user.id);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final account = authState.account;
    final theme = Theme.of(context);

    if (user == null || account == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic would go here
        ref.invalidate(recentTransactionsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header and Notifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: theme.textTheme.bodyMedium,
                      ).animate().fadeIn(),
                      const SizedBox(height: 4),
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                        ),
                      ).animate().slideX(begin: -0.1).fadeIn(),
                    ],
                  ),
                  _buildNotificationBell(ref),
                ],
              ),
              const SizedBox(height: 24),

              // Balance Card
              _buildBalanceCard(
                context,
                account.balance,
              ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              _buildQuickActions(
                context,
              ).animate().slideY(begin: 0.1, delay: 400.ms).fadeIn(),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton(onPressed: () {}, child: const Text('See All')),
                ],
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 8),
              _buildRecentTransactions(ref).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Card(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Icon(Icons.visibility_off, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'RWF ${balance.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text(
                      'Top Up',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TransferScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Transfer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionIcon(
          icon: Icons.receipt,
          label: 'Pay Bills',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const user_bills.PayBillsScreen(),
              ),
            );
          },
        ),
        _ActionIcon(
          icon: Icons.phone_iphone,
          label: 'Airtime',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const user_airtime.AirtimeTopUpScreen(),
              ),
            );
          },
        ),
        _ActionIcon(
          icon: Icons.account_balance_wallet,
          label: 'Save',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const user_fd.FixedDepositScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No recent transactions')),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isDeposit = tx.type == 'deposit';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDeposit
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  tx.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(tx.createdAt?.substring(0, 10) ?? 'Recent'),
                trailing: Text(
                  '${isDeposit ? '+' : '-'} RWF ${tx.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading transactions: $e'),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, size: 28),
              onPressed: () {
                // In a real app this would open a notifications bottom sheet or dialog
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const IconButton(
        icon: Icon(Icons.notifications_none, size: 28),
        onPressed: null,
      ),
      error: (_, __) => const IconButton(
        icon: Icon(Icons.notifications_none, size: 28),
        onPressed: null,
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
