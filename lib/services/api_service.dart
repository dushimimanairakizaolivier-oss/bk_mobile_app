import '../models/user.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/notification.dart';
import '../models/fixed_deposit.dart';
import '../models/audit_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'dart:math';

class ApiService {
  final DatabaseService _db = DatabaseService.instance;

  ApiService();

  // Helper function to extract a single row
  Map<String, dynamic>? _firstRow(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final rows = await _db.rawQuery('SELECT * FROM users WHERE email = ?', [
      email,
    ]);
    final userMap = _firstRow(rows);

    if (userMap != null) {
      final hashedPassword = _db.hashPassword(password);
      if (userMap['password'] == hashedPassword) {
        final accountRows = await _db.rawQuery(
          'SELECT * FROM accounts WHERE user_id = ?',
          [userMap['id']],
        );
        final accountMap = _firstRow(accountRows);

        return {
          'user': User.fromJson(userMap),
          'account': accountMap != null ? Account.fromJson(accountMap) : null,
        };
      }
    }
    throw Exception('Invalid credentials');
  }

  // User Data
  Future<Account> getAccount(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM accounts WHERE user_id = ?',
      [userId],
    );
    final accountMap = _firstRow(rows);
    if (accountMap == null) throw Exception('Account not found');
    return Account.fromJson(accountMap);
  }

  Future<List<Notification>> getNotifications(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );
    return rows.map((json) => Notification.fromJson(json)).toList();
  }

  Future<List<Transaction>> getTransactions(int userId) async {
    final accountRows = await _db.rawQuery(
      'SELECT id FROM accounts WHERE user_id = ?',
      [userId],
    );
    final accountMap = _firstRow(accountRows);
    if (accountMap == null) return [];

    final rows = await _db.rawQuery(
      'SELECT * FROM transactions WHERE account_id = ? ORDER BY created_at DESC',
      [accountMap['id']],
    );
    return rows.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<List<Loan>> getLoans(int userId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT loans.*, users.name as user_name, accounts.account_number 
      FROM loans
      LEFT JOIN users ON loans.user_id = users.id
      LEFT JOIN accounts ON loans.user_id = accounts.user_id
      WHERE loans.user_id = ? 
      ORDER BY loans.created_at DESC
    ''',
      [userId],
    );
    return rows.map((json) => Loan.fromJson(json)).toList();
  }

  Future<List<FixedDeposit>> getFixedDeposits(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM fixed_deposits WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );
    return rows.map((json) => FixedDeposit.fromJson(json)).toList();
  }

  // User Actions
  Future<bool> transfer(
    int fromUserId,
    String toAccountNumber,
    double amount,
    String description,
  ) async {
    final db = await _db.database;

    final senderRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE user_id = ?',
      [fromUserId],
    );
    final senderAccount = _firstRow(senderRows);
    if (senderAccount == null) throw Exception('Your account not found');
    if (senderAccount['status'] == 'frozen')
      throw Exception('Your account is frozen. Please contact the bank.');
    if ((senderAccount['balance'] as num) < amount)
      throw Exception('Insufficient funds');

    final receiverRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE account_number = ?',
      [toAccountNumber],
    );
    final receiverAccount = _firstRow(receiverRows);
    if (receiverAccount == null) throw Exception('Recipient account not found');
    if (receiverAccount['id'] == senderAccount['id'])
      throw Exception('Cannot transfer to the same account');

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, senderAccount['id']],
      );
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, receiverAccount['id']],
      );

      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description, related_account_number) VALUES (?, ?, ?, ?, ?)',
        [
          senderAccount['id'],
          'transfer',
          -amount,
          description.isEmpty ? 'Transfer to $toAccountNumber' : description,
          toAccountNumber,
        ],
      );

      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description, related_account_number) VALUES (?, ?, ?, ?, ?)',
        [
          receiverAccount['id'],
          'transfer',
          amount,
          'Transfer from ${senderAccount['account_number']}',
          senderAccount['account_number'],
        ],
      );

      await txn.rawInsert(
        'INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)',
        [
          receiverAccount['user_id'],
          'Payment Received',
          'You received RWF $amount from ${senderAccount['account_number']}',
        ],
      );
    });

    return true;
  }

  Future<bool> applyLoan(int userId, double amount, String purpose) async {
    final db = await _db.database;
    await db.rawInsert(
      'INSERT INTO loans (user_id, amount, purpose) VALUES (?, ?, ?)',
      [userId, amount, purpose],
    );
    return true;
  }

  Future<bool> topUpAirtime(
    int userId,
    String phoneNumber,
    double amount,
    String provider,
  ) async {
    final db = await _db.database;
    final accountRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE user_id = ?',
      [userId],
    );
    final account = _firstRow(accountRows);

    if (account == null) throw Exception('Account not found');
    if (account['status'] == 'frozen') throw Exception('Account is frozen');
    if ((account['balance'] as num) < amount)
      throw Exception('Insufficient funds');

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, account['id']],
      );
      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description) VALUES (?, ?, ?, ?)',
        [
          account['id'],
          'withdrawal',
          -amount,
          'Airtime Topup: $phoneNumber ($provider)',
        ],
      );
    });
    return true;
  }

  Future<bool> payBill(
    int userId,
    String biller,
    String reference,
    double amount,
  ) async {
    final db = await _db.database;
    final accountRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE user_id = ?',
      [userId],
    );
    final account = _firstRow(accountRows);

    if (account == null) throw Exception('Account not found');
    if (account['status'] == 'frozen') throw Exception('Account is frozen');
    if ((account['balance'] as num) < amount)
      throw Exception('Insufficient funds');

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, account['id']],
      );
      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description) VALUES (?, ?, ?, ?)',
        [
          account['id'],
          'withdrawal',
          -amount,
          'Bill Payment: $biller ($reference)',
        ],
      );
    });
    return true;
  }

  Future<bool> openFixedDeposit(
    int userId,
    double amount,
    int termMonths,
  ) async {
    final db = await _db.database;
    final accountRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE user_id = ?',
      [userId],
    );
    final account = _firstRow(accountRows);

    if (account == null) throw Exception('Account not found');
    if (account['status'] == 'frozen') throw Exception('Account is frozen');
    if ((account['balance'] as num) < amount)
      throw Exception('Insufficient funds');

    final rate = termMonths >= 12 ? 0.08 : 0.05;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, account['id']],
      );
      await txn.rawInsert(
        'INSERT INTO fixed_deposits (user_id, amount, term_months, interest_rate) VALUES (?, ?, ?, ?)',
        [userId, amount, termMonths, rate],
      );
      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description) VALUES (?, ?, ?, ?)',
        [
          account['id'],
          'withdrawal',
          -amount,
          'Opened Fixed Deposit: $termMonths months',
        ],
      );
    });
    return true;
  }

  // Admin Actions
  Future<List<User>> getAllUsers() async {
    final rows = await _db.rawQuery('''
      SELECT users.*, accounts.account_number, accounts.balance 
      FROM users 
      LEFT JOIN accounts ON users.id = accounts.user_id
      WHERE users.role = 'user'
    ''');
    return rows.map((json) => User.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    final db = await _db.database;
    final hashedPassword = _db.hashPassword(customerData['password']);

    Map<String, dynamic> result = {};

    await db.transaction((txn) async {
      final userId = await txn.rawInsert(
        'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
        [customerData['name'], customerData['email'], hashedPassword],
      );

      final String firstDigit = (Random().nextInt(9) + 1).toString();
      final String remainingDigits = Random()
          .nextInt(1000000000)
          .toString()
          .padLeft(9, '0');
      final accountNumber = 'BK$firstDigit$remainingDigits';

      await txn.rawInsert(
        'INSERT INTO accounts (user_id, account_number, balance, type) VALUES (?, ?, ?, ?)',
        [
          userId,
          accountNumber,
          customerData['initialBalance'] ?? 0,
          customerData['accountType'] ?? 'savings',
        ],
      );

      result = {
        'success': true,
        'userId': userId,
        'accountNumber': accountNumber,
      };
    });

    return result;
  }

  Future<bool> adminDeposit(
    String accountNumber,
    double amount,
    String description,
  ) async {
    final db = await _db.database;
    final accountRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE account_number = ?',
      [accountNumber],
    );
    final account = _firstRow(accountRows);
    if (account == null) throw Exception('Account not found');

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, account['id']],
      );
      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description) VALUES (?, ?, ?, ?)',
        [
          account['id'],
          'deposit',
          amount,
          description.isEmpty ? 'Admin Deposit' : description,
        ],
      );
    });
    return true;
  }

  Future<bool> adminTransfer(
    String fromAccount,
    String toAccount,
    double amount,
    String description,
  ) async {
    final db = await _db.database;

    final senderRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE account_number = ?',
      [fromAccount],
    );
    final senderAccount = _firstRow(senderRows);

    final receiverRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE account_number = ?',
      [toAccount],
    );
    final receiverAccount = _firstRow(receiverRows);

    if (senderAccount == null || receiverAccount == null)
      throw Exception('One or both accounts not found');
    if ((senderAccount['balance'] as num) < amount)
      throw Exception('Insufficient funds');

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, senderAccount['id']],
      );
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, receiverAccount['id']],
      );

      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description, related_account_number) VALUES (?, ?, ?, ?, ?)',
        [
          senderAccount['id'],
          'transfer',
          -amount,
          description.isEmpty ? 'Transfer Out' : description,
          toAccount,
        ],
      );
      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description, related_account_number) VALUES (?, ?, ?, ?, ?)',
        [
          receiverAccount['id'],
          'transfer',
          amount,
          description.isEmpty ? 'Transfer In' : description,
          fromAccount,
        ],
      );
    });
    return true;
  }

  Future<List<Loan>> getAdminLoans() async {
    final rows = await _db.rawQuery('''
      SELECT loans.*, users.name as user_name, accounts.account_number 
      FROM loans
      LEFT JOIN users ON loans.user_id = users.id
      LEFT JOIN accounts ON loans.user_id = accounts.user_id
      ORDER BY loans.created_at DESC
    ''');
    return rows.map((json) => Loan.fromJson(json)).toList();
  }

  Future<bool> approveLoan(int loanId) async {
    final db = await _db.database;
    final loanRows = await db.rawQuery('SELECT * FROM loans WHERE id = ?', [
      loanId,
    ]);
    final loan = _firstRow(loanRows);

    if (loan == null) throw Exception('Loan not found');
    if (loan['status'] != 'pending') throw Exception('Loan already processed');

    final accountRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE user_id = ?',
      [loan['user_id']],
    );
    final account = _firstRow(accountRows);
    if (account == null) throw Exception('Account not found');

    await db.transaction((txn) async {
      await txn.rawUpdate("UPDATE loans SET status = 'approved' WHERE id = ?", [
        loanId,
      ]);
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [loan['amount'], account['id']],
      );
      await txn.rawInsert(
        'INSERT INTO transactions (account_id, type, amount, description) VALUES (?, ?, ?, ?)',
        [
          account['id'],
          'loan_disbursement',
          loan['amount'],
          'Loan Approved: ${loan['purpose']}',
        ],
      );
      // notify the borrower that loan has been approved
      await txn.rawInsert(
        'INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)',
        [
          loan['user_id'],
          'Loan Approved',
          'Your loan for RWF ${loan['amount']} has been approved.',
        ],
      );
    });
    return true;
  }

  Future<bool> updateAccountStatusByNumber(
    String accountNumber,
    String status,
    int adminId,
  ) async {
    final db = await _db.database;
    final accountRows = await db.rawQuery(
      'SELECT * FROM accounts WHERE account_number = ?',
      [accountNumber],
    );
    final account = _firstRow(accountRows);

    if (account == null) throw Exception('Account not found');

    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE accounts SET status = ? WHERE id = ?', [
        status,
        account['id'],
      ]);
      await txn.rawInsert(
        'INSERT INTO audit_logs (admin_id, action, details) VALUES (?, ?, ?)',
        [
          adminId,
          'account_$status',
          'Changed status of account $accountNumber to $status',
        ],
      );
    });
    return true;
  }

  Future<List<AuditLog>> getAuditLogs() async {
    final rows = await _db.rawQuery(
      'SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 100',
    );
    return rows.map((json) => AuditLog.fromJson(json)).toList();
  }
}

// Global provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
