import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart'; // To invalidate recent txs

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _handleTransfer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(authProvider).user;
        if (user == null) throw Exception('User not authenticated');

        final amount = double.parse(_amountController.text);
        final success = await ref.read(apiServiceProvider).transfer(
              user.id,
              _accountController.text,
              amount,
              _descriptionController.text,
            );

        if (success && mounted) {
          // Invalidate transactions so dashboard updates
          ref.invalidate(recentTransactionsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer successful!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transfer failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.send_to_mobile, size: 60, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Send to anyone in BK',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().scale(delay: 100.ms),
              const SizedBox(height: 32),
              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Account Number',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Enter account number' : null,
              ).animate().slideX(begin: 0.2, delay: 200.ms).fadeIn(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (RWF)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val!.isEmpty) return 'Enter amount';
                  if (double.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
              ).animate().slideX(begin: 0.2, delay: 300.ms).fadeIn(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ).animate().slideX(begin: 0.2, delay: 400.ms).fadeIn(),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleTransfer,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().slideY(begin: 0.2, delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
