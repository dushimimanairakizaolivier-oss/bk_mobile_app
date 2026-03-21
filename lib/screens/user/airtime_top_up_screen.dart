import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../dashboard_screen.dart';

class AirtimeTopUpScreen extends ConsumerStatefulWidget {
  const AirtimeTopUpScreen({super.key});

  @override
  ConsumerState<AirtimeTopUpScreen> createState() => _AirtimeTopUpScreenState();
}

class _AirtimeTopUpScreenState extends ConsumerState<AirtimeTopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _provider = 'MTN';
  String _phone = '';
  String _amount = '';
  bool _isLoading = false;

  Future<void> _handleTopup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('User not found');

      await ref.read(apiServiceProvider).topUpAirtime(
        user.id,
        _phone,
        double.parse(_amount),
        _provider,
      );

      if (mounted) {
        // Refresh account details
        await ref.read(authProvider.notifier).refreshAccount();
        // Refresh recent transactions
        ref.invalidate(recentTransactionsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully topped up RWF $_amount to $_phone')),
        );
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Airtime Topup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Provider',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['MTN', 'Airtel'].map((p) {
                  final isSelected = _provider == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                          foregroundColor: isSelected ? Colors.white : Colors.grey,
                          elevation: 0,
                        ),
                        onPressed: () => setState(() => _provider = p),
                        child: Text(p),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '078XXXXXXX',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.phone,
                validator: (values) => values!.isEmpty ? 'Enter phone number' : null,
                onSaved: (value) => _phone = value!,
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Amount (RWF)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                validator: (values) => values!.isEmpty ? 'Enter amount' : null,
                onSaved: (value) => _amount = value!,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleTopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Top Up Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
