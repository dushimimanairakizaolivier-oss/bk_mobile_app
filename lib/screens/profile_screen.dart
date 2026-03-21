import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final account = ref.watch(authProvider).account;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.name),
              subtitle: Text(user.email),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Account Number'),
              subtitle: Text(account?.accountNumber ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Balance'),
              subtitle: Text('RWF ${account?.balance.toStringAsFixed(0) ?? '0'}'),
            ),
          ],
        ),
      ),
    );
  }
}
