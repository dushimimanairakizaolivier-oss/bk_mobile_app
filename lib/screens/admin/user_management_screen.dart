import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

final usersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  return ref.read(apiServiceProvider).getAllUsers();
});

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final adminId = ref.read(authProvider).user?.id ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(usersProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCustomerDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No customers found.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isFrozen = user.status == 'frozen';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isFrozen ? Colors.red.withAlpha(50) : Colors.transparent,
                    width: isFrozen ? 2 : 0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isFrozen ? Colors.red : Theme.of(context).primaryColor,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.email),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InfoRow(label: 'Account No:', value: user.accountNumber ?? 'N/A'),
                          const SizedBox(height: 8),
                          _InfoRow(label: 'Balance:', value: 'RWF ${user.balance?.toStringAsFixed(0) ?? '0'}'),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Status:',
                            value: user.status.toUpperCase(),
                            valueColor: isFrozen ? Colors.red : Colors.green,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final newStatus = isFrozen ? 'active' : 'frozen';
                              final success = await _confirmAction(
                                context,
                                title: '${isFrozen ? 'Unfreeze' : 'Freeze'} Account?',
                                content: 'Are you sure you want to ${isFrozen ? 'unfreeze' : 'freeze'} ${user.name}\'s account?',
                                onConfirm: () => ref.read(apiServiceProvider).updateAccountStatusByNumber(
                                  user.accountNumber ?? 'N/A',
                                  newStatus,
                                  adminId,
                                ),
                              );

                              if (success) {
                                ref.invalidate(usersProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Account $newStatus successfully')),
                                  );
                                }
                              }
                            },
                            icon: Icon(isFrozen ? Icons.lock_open : Icons.lock, color: Colors.white),
                            label: Text(isFrozen ? 'Unfreeze Account' : 'Freeze Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFrozen ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showCreateCustomerDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String password = '';
    double initialBalance = 0.0;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Customer'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => name = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@') ? 'Invalid Email' : null,
                    onSaved: (v) => email = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                    onSaved: (v) => password = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Initial Balance (RWF)'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => initialBalance = double.tryParse(v ?? '0') ?? 0.0,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  
                  try {
                    await ref.read(apiServiceProvider).createCustomer({
                      'name': name,
                      'email': email,
                      'password': password,
                      'initialBalance': initialBalance,
                      'accountType': 'savings',
                    });
                    
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      ref.invalidate(usersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer created successfully')),
        );
      }
    }
  }

  Future<bool> _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await onConfirm();
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                  Navigator.pop(context, false);
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
