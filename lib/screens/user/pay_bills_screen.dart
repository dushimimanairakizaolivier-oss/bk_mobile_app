import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../dashboard_screen.dart';

class PayBillsScreen extends ConsumerStatefulWidget {
  const PayBillsScreen({super.key});

  @override
  ConsumerState<PayBillsScreen> createState() => _PayBillsScreenState();
}

class _PayBillsScreenState extends ConsumerState<PayBillsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _biller = 'REG (Electricity)';
  String _reference = '';
  String _amount = '';
  bool _isLoading = false;

  final List<String> _billers = [
    'REG (Electricity)',
    'WASAC (Water)',
    'RRA (Taxes)',
    'Irembo',
  ];

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('User not found');

      await ref.read(apiServiceProvider).payBill(
        user.id,
        _biller,
        _reference,
        double.parse(_amount),
      );

      if (mounted) {
        await ref.read(authProvider.notifier).refreshAccount();
        ref.invalidate(recentTransactionsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully paid RWF $_amount to $_biller')),
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
      appBar: AppBar(title: const Text('Pay Bills')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _biller,
                decoration: InputDecoration(
                  labelText: 'Biller',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _billers.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => setState(() => _biller = val!),
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Reference Number',
                  hintText: 'Meter or Account No.',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (values) => values!.isEmpty ? 'Enter reference number' : null,
                onSaved: (value) => _reference = value!,
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
                onPressed: _isLoading ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Pay Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
