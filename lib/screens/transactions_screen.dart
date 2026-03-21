import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.read(apiServiceProvider).getTransactions(user.id);
});

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(transactionsProvider),
          ),
        ],
      ),
      body: txAsync.when(
        data: (txs) {
          if (txs.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }
          return ListView.separated(
            itemCount: txs.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (c, i) {
              final tx = txs[i];
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
                title: Text(tx.description),
                subtitle: Text(tx.createdAt?.substring(0, 10) ?? ''),
                trailing: Text(
                  '${isDeposit ? '+' : '-'} RWF ${tx.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
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
}
