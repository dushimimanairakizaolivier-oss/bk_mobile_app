import 'package:flutter/material.dart';
import 'user/airtime_top_up_screen.dart' as user_airtime;
import 'user/pay_bills_screen.dart' as user_bills;
import 'user/fixed_deposit_screen.dart' as user_fd;
import 'user/user_loans_screen.dart' as user_loans;

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _ServiceTile(
              icon: Icons.receipt,
              label: 'Pay Bills',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const user_bills.PayBillsScreen()),
              ),
            ),
            _ServiceTile(
              icon: Icons.phone_iphone,
              label: 'Airtime',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const user_airtime.AirtimeTopUpScreen()),
              ),
            ),
            _ServiceTile(
              icon: Icons.monetization_on,
              label: 'Loans',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const user_loans.UserLoansScreen()),
              ),
            ),
            _ServiceTile(
              icon: Icons.account_balance_wallet,
              label: 'Fixed Deposit',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const user_fd.FixedDepositScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
