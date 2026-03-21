import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/loan.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../admin/loan_approvals_screen.dart';
import 'package:intl/intl.dart';

final userLoansProvider = FutureProvider.autoDispose<List<Loan>>((ref) async {
  final user = ref.read(authProvider).user;
  if (user == null) return [];
  return ref.read(apiServiceProvider).getLoans(user.id);
});

class UserLoansScreen extends ConsumerStatefulWidget {
  const UserLoansScreen({super.key});

  @override
  ConsumerState<UserLoansScreen> createState() => _UserLoansScreenState();
}

class _UserLoansScreenState extends ConsumerState<UserLoansScreen> {
  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(userLoansProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: 'RWF ',
      decimalDigits: 0,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userLoansProvider),
          ),
        ],
      ),
      body: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.money_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'You have no loans.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showApplyLoanDialog(context, ref),
                    child: const Text('Apply for a Loan'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showApplyLoanDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Apply for a New Loan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 600) {
                      // Tablet/Desktop view
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: loans.length,
                        itemBuilder: (context, index) =>
                            _buildLoanCard(loans[index], currencyFormat, theme),
                      );
                    } else {
                      // Mobile view
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: loans.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildLoanCard(
                            loans[index],
                            currencyFormat,
                            theme,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildLoanCard(
    Loan loan,
    NumberFormat currencyFormat,
    ThemeData theme,
  ) {
    final isPending = loan.status == 'pending';
    final isApproved = loan.status == 'approved';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending ? Colors.blue.withAlpha(100) : Colors.transparent,
          width: isPending ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    loan.purpose,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.blue.withAlpha(50)
                        : isApproved
                        ? Colors.green.withAlpha(50)
                        : Colors.red.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loan.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? Colors.blue.shade800
                          : isApproved
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currencyFormat.format(loan.amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Applied on: ${loan.createdAt?.substring(0, 10) ?? 'Unknown'}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyLoanDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Loan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (RWF)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a purpose';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final user = ref.read(authProvider).user;
                if (user != null) {
                  try {
                    await ref
                        .read(apiServiceProvider)
                        .applyLoan(
                          user.id,
                          double.parse(amountController.text),
                          purposeController.text,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      // refresh both the user view and admin approvals
                      ref.invalidate(userLoansProvider);
                      ref.invalidate(adminLoansProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loan application submitted'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
