import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/fixed_deposit.dart';
import '../dashboard_screen.dart';

final fixedDepositsProvider = FutureProvider.autoDispose<List<FixedDeposit>>((ref) async {
  final user = ref.read(authProvider).user;
  if (user == null) return [];
  return ref.read(apiServiceProvider).getFixedDeposits(user.id);
});

class FixedDepositScreen extends ConsumerStatefulWidget {
  const FixedDepositScreen({super.key});

  @override
  ConsumerState<FixedDepositScreen> createState() => _FixedDepositScreenState();
}

class _FixedDepositScreenState extends ConsumerState<FixedDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  String _term = '6';
  String _amount = '';
  bool _isLoading = false;

  Future<void> _handleOpen() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('User not found');

      await ref.read(apiServiceProvider).openFixedDeposit(
        user.id,
        double.parse(_amount),
        int.parse(_term),
      );

      if (mounted) {
        await ref.read(authProvider.notifier).refreshAccount();
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(fixedDepositsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully opened Fixed Deposit')),
        );
        _formKey.currentState!.reset(); // Clear form if continuing to view list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final depositsAsync = ref.watch(fixedDepositsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fixed Deposits')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interest Rates:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 8),
                  Text('• 6 Months: 5% p.a.', style: TextStyle(color: Colors.blue)),
                  Text('• 12+ Months: 8% p.a.', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Amount (RWF)',
                      hintText: 'Min RWF 100,000',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (values) => values!.isEmpty ? 'Enter amount' : null,
                    onSaved: (value) => _amount = value!,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _term,
                    decoration: InputDecoration(
                      labelText: 'Term (Months)',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: '6', child: Text('6 Months')),
                      DropdownMenuItem(value: '12', child: Text('12 Months')),
                      DropdownMenuItem(value: '24', child: Text('24 Months')),
                    ],
                    onChanged: (val) => setState(() => _term = val!),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleOpen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Open Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            const Text('Your Fixed Deposits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            depositsAsync.when(
              data: (deposits) {
                if (deposits.isEmpty) return const Text('No fixed deposits opened yet.', style: TextStyle(color: Colors.grey));
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deposits.length,
                  itemBuilder: (context, index) {
                    final d = deposits[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                        title: Text('RWF ${d.amount.toStringAsFixed(0)}'),
                        subtitle: Text('${d.termMonths} Months @ ${(d.interestRate * 100).toStringAsFixed(0)}%'),
                        trailing: Text(d.status.toUpperCase(), style: TextStyle(color: d.status == 'active' ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
