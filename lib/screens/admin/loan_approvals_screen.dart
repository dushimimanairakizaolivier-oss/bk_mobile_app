import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/loan.dart';
import '../../services/api_service.dart';
import '../user/user_loans_screen.dart';
import 'package:intl/intl.dart';

final adminLoansProvider = FutureProvider.autoDispose<List<Loan>>((ref) async {
  return ref.read(apiServiceProvider).getAdminLoans();
});

class LoanApprovalsScreen extends ConsumerWidget {
  const LoanApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(adminLoansProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: 'RWF ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminLoansProvider),
          ),
        ],
      ),
      body: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return const Center(child: Text('No loans found.'));
          }

          // Sort so pending loans are at the top
          final sortedLoans = List<Loan>.from(loans)
            ..sort((a, b) {
              if (a.status == 'pending' && b.status != 'pending') return -1;
              if (a.status != 'pending' && b.status == 'pending') return 1;
              return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
            });

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                // Desktop view
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: sortedLoans.length,
                  itemBuilder: (context, index) => _buildLoanCard(
                    context,
                    ref,
                    sortedLoans[index],
                    currencyFormat,
                  ),
                );
              } else if (constraints.maxWidth >= 600) {
                // Tablet view
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: sortedLoans.length,
                  itemBuilder: (context, index) => _buildLoanCard(
                    context,
                    ref,
                    sortedLoans[index],
                    currencyFormat,
                  ),
                );
              } else {
                // Mobile view
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sortedLoans.length,
                  itemBuilder: (context, index) => _buildLoanCard(
                    context,
                    ref,
                    sortedLoans[index],
                    currencyFormat,
                  ),
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    WidgetRef ref,
    Loan loan,
    NumberFormat currencyFormat,
  ) {
    final isPending = loan.status == 'pending';
    final isApproved = loan.status == 'approved';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isPending ? Colors.blue.withAlpha(100) : Colors.transparent,
          width: isPending ? 2 : 0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Added for GridView compatibility
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
            _InfoRow(label: 'Applicant ID:', value: loan.id.toString()),
            const SizedBox(height: 4),
            _InfoRow(label: 'Name:', value: loan.userName ?? 'N/A'),
            const SizedBox(height: 4),
            _InfoRow(label: 'Account:', value: loan.accountNumber ?? 'N/A'),
            const SizedBox(height: 4),
            _InfoRow(
              label: 'Amount:',
              value: currencyFormat.format(loan.amount),
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: 'Date:',
              value: loan.createdAt?.substring(0, 10) ?? 'N/A',
            ),
            // remove spacer; using fixed gap before the action button
            if (isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Approve Loan?'),
                        content: Text(
                          'Are you sure you want to approve this loan for ${currencyFormat.format(loan.amount)}?\n\nThis will immediately disburse the funds into the applicant\'s account.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await ref.read(apiServiceProvider).approveLoan(loan.id);
                        // refresh both admin and any open user loan views on this device
                        ref.invalidate(adminLoansProvider);
                        ref.invalidate(userLoansProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Loan approved successfully. Funds dispersed.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error approving loan: $e')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Approve & Disburse Funds',
                    style: TextStyle(fontSize: 13),
                  ), // reduced font size slightly for GridView
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
