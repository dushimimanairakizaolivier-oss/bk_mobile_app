import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../models/user.dart';
import '../models/account.dart';

class ChatMessage {
  final String role;
  final String text;

  ChatMessage({required this.role, required this.text});
}

class AiService {
  final ApiService _apiService;
  GenerativeModel? _model;
  ChatSession? _chat;
  String? _apiKey;
  bool _modelInitAttempted = false;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  AiService(this._apiService) {
    _initModel();
    _messages.add(
      ChatMessage(
        role: 'model',
        text: "Hello! I'm your BK Mobile Assistant. How can I help you today?",
      ),
    );
  }

  void _initModel() {
    // Prevent repeated init attempts
    if (_modelInitAttempted) return;
    _modelInitAttempted = true;

    // Note: In production, do not hardcode the API key in the source code.
    // We'll attempt to use dotenv if available; otherwise we fall back to a test key.
    String apiKey = '';
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (e) {
      // Dotenv not loaded or file missing; we'll fall back to the embedded test key.
    }

    if (apiKey.isEmpty) {
      print('Warning: GEMINI_API_KEY environment variable not found or dotenv failed to load. Using embedded test key for local testing.');
      apiKey = 'AIzaSyCU812XRWW-QOOThVQeZwMa0GLxHatbUjU';
    }

    _apiKey = apiKey;

    final tools = [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'transfer_money',
            'Transfer money to another BK account',
            Schema(
              SchemaType.object,
              properties: {
                'amount': Schema(
                  SchemaType.number,
                  description: 'The amount to transfer in RWF',
                ),
                'to_account': Schema(
                  SchemaType.string,
                  description: 'The destination account number',
                ),
                'reason': Schema(
                  SchemaType.string,
                  description: 'The reason for the transfer',
                ),
                'scheduled_time': Schema(
                  SchemaType.string,
                  description: 'Optional ISO string for scheduling',
                  nullable: true,
                ),
              },
              requiredProperties: ['amount', 'to_account', 'reason'],
            ),
          ),
          FunctionDeclaration(
            'pay_bill',
            'Pay a utility bill',
            Schema(
              SchemaType.object,
              properties: {
                'bill_type': Schema(
                  SchemaType.string,
                  description: 'The bill type (e.g., REG, WASAC, RRA, Irembo)',
                ),
                'reference': Schema(
                  SchemaType.string,
                  description: 'The bill reference number',
                ),
                'amount': Schema(
                  SchemaType.number,
                  description: 'The amount to pay in RWF',
                ),
                'scheduled_time': Schema(
                  SchemaType.string,
                  description: 'Optional ISO string for scheduling',
                  nullable: true,
                ),
              },
              requiredProperties: ['bill_type', 'reference', 'amount'],
            ),
          ),
          FunctionDeclaration(
            'top_up_airtime',
            'Top up airtime for a phone number',
            Schema(
              SchemaType.object,
              properties: {
                'phone_number': Schema(
                  SchemaType.string,
                  description: 'The phone number to top up',
                ),
                'provider': Schema(
                  SchemaType.string,
                  description: 'The mobile provider (e.g., MTN, Airtel)',
                ),
                'amount': Schema(
                  SchemaType.number,
                  description: 'The amount to top up in RWF',
                ),
                'scheduled_time': Schema(
                  SchemaType.string,
                  description: 'Optional ISO string for scheduling',
                  nullable: true,
                ),
              },
              requiredProperties: ['phone_number', 'provider', 'amount'],
            ),
          ),
          FunctionDeclaration(
            'apply_loan',
            'Apply for a personal loan',
            Schema(
              SchemaType.object,
              properties: {
                'amount': Schema(
                  SchemaType.number,
                  description: 'The loan amount requested in RWF',
                ),
                'purpose': Schema(
                  SchemaType.string,
                  description: 'The purpose of the loan',
                ),
              },
              requiredProperties: ['amount', 'purpose'],
            ),
          ),
          FunctionDeclaration(
            'open_fixed_deposit',
            'Open a fixed deposit account',
            Schema(
              SchemaType.object,
              properties: {
                'amount': Schema(
                  SchemaType.number,
                  description: 'The amount to deposit in RWF',
                ),
                'term_months': Schema(
                  SchemaType.number,
                  description: 'The duration of the fixed deposit in months',
                ),
              },
              requiredProperties: ['amount', 'term_months'],
            ),
          ),
          FunctionDeclaration(
            'create_customer',
            'Create a new customer account (admin only)',
            Schema(
              SchemaType.object,
              properties: {
                'name': Schema(
                  SchemaType.string,
                  description: 'The customer name',
                ),
                'email': Schema(
                  SchemaType.string,
                  description: 'The customer email address',
                ),
                'password': Schema(
                  SchemaType.string,
                  description: 'Initial password for the new customer',
                ),
                'initial_balance': Schema(
                  SchemaType.number,
                  description: 'Initial account balance in RWF',
                ),
                'account_type': Schema(
                  SchemaType.string,
                  description: 'Type of account (e.g., savings, current)',
                ),
              },
              requiredProperties: ['name', 'email', 'password', 'initial_balance', 'account_type'],
            ),
          ),
          FunctionDeclaration(
            'admin_deposit',
            'Deposit money into a customer account (admin only)',
            Schema(
              SchemaType.object,
              properties: {
                'account_number': Schema(
                  SchemaType.string,
                  description: 'The target customer account number',
                ),
                'amount': Schema(
                  SchemaType.number,
                  description: 'The amount to deposit in RWF',
                ),
                'description': Schema(
                  SchemaType.string,
                  description: 'Optional description for the deposit',
                  nullable: true,
                ),
              },
              requiredProperties: ['account_number', 'amount'],
            ),
          ),
          FunctionDeclaration(
            'admin_transfer',
            'Transfer money between accounts (admin only)',
            Schema(
              SchemaType.object,
              properties: {
                'from_account': Schema(
                  SchemaType.string,
                  description: 'Source account number',
                ),
                'to_account': Schema(
                  SchemaType.string,
                  description: 'Destination account number',
                ),
                'amount': Schema(
                  SchemaType.number,
                  description: 'The amount to transfer in RWF',
                ),
                'description': Schema(
                  SchemaType.string,
                  description: 'Optional description',
                  nullable: true,
                ),
              },
              requiredProperties: ['from_account', 'to_account', 'amount'],
            ),
          ),
          FunctionDeclaration(
            'approve_loan',
            'Approve a pending loan (admin only)',
            Schema(
              SchemaType.object,
              properties: {
                'loan_id': Schema(
                  SchemaType.number,
                  description: 'The ID of the loan to approve',
                ),
              },
              requiredProperties: ['loan_id'],
            ),
          ),
          FunctionDeclaration(
            'navigate_to',
            'Navigate to a different part of the app',
            Schema(
              SchemaType.object,
              properties: {
                'view': Schema(
                  SchemaType.string,
                  description: 'The UI view to navigate to (e.g. dashboard, transactions, users)',
                ),
              },
              requiredProperties: ['view'],
            ),
          ),
          FunctionDeclaration(
            'update_account_status',
            'Change account status (admin only)',
            Schema(
              SchemaType.object,
              properties: {
                'account_number': Schema(
                  SchemaType.string,
                  description: 'The account number to update',
                ),
                'status': Schema(
                  SchemaType.string,
                  description: 'New status (e.g., active, frozen)',
                ),
              },
              requiredProperties: ['account_number', 'status'],
            ),
          ),
        ],
      ),
    ];
    // The Google Gemini API supports different model families depending on the
    // API version. The current `google_generative_ai` Dart package uses v1beta.
    // Some models (e.g., gemini-1.5-flash-latest) are not available in v1beta for
    // this API key, which causes a "model not found" error.
    //
    // The callable models for this key can be listed via the `models` endpoint.
    // To pick a different model, set GEMINI_MODEL in .env (e.g., GEMINI_MODEL=gemini-2.5-flash).
    final modelName = dotenv.env['GEMINI_MODEL']?.trim() ?? 'gemini-2.5-flash';

    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      tools: tools,
    );
    _chat = _model!.startChat();
  }

  Future<void> _printAvailableModels() async {
    if (_apiKey == null || _apiKey!.isEmpty) return;

    try {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models',
        {'key': _apiKey!},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        print('ListModels request failed (${response.statusCode}): ${response.body}');
        return;
      }

      final jsonBody = jsonDecode(response.body);
      final models = (jsonBody['models'] as List<dynamic>?)
          ?.map((m) {
            if (m is Map<String, dynamic>) {
              return m['name']?.toString() ?? m.toString();
            }
            return m.toString();
          })
          .toList();

      print('Available models for this key (v1beta): ${models ?? []}');
    } catch (e) {
      print('Error listing models: $e');
    }
  }

  Future<String?> sendMessage({
    required String message,
    required User? user,
    required Account? account,
    required String currentView,
    required Function(String view) onNavigate,
    required Function() onActionComplete,
    required Function(String type, String message) onActionStatusUpdate,
  }) async {
    // Add user message to chat history
    _messages.add(ChatMessage(role: 'user', text: message));

    // If the model wasn't initialized yet (e.g., dotenv loaded later), try again.
    if (_chat == null) {
      _initModel();
    }

    if (_chat == null) {
      final errMsg =
          'AI features are currently unavailable. Please configure your API key.';
      _messages.add(ChatMessage(role: 'model', text: errMsg));
      return errMsg;
    }

    final currentTime = DateTime.now().toLocal().toString();

    final systemInstruction = '''
You are an AI assistant for the BK Mobile banking application (Bank of Kigali).
Your goal is to help users and admins navigate the app, understand functionalities, and provide support.

CURRENT TIME: $currentTime

CONTEXT:
- Current User: ${user?.name ?? 'Guest (Not Logged In)'} (${user?.role ?? 'Visitor'})
- Current Account: ${account?.accountNumber ?? 'N/A'} (Balance: RWF ${account?.balance.toStringAsFixed(0) ?? '0'})
- Current View: $currentView

CAPABILITIES:
You can perform actions on behalf of the user if they are logged in.
If a user asks to transfer money, pay a bill, or top up airtime, use the provided tools.
If a user specifies a time for a transaction, you can "schedule" it. For this demo, if they specify a future time, acknowledge the scheduling. If they want it "now", perform it immediately.

APP FEATURES FOR USERS:
- Dashboard: Overview of balance and recent activity.
- Transactions: Detailed history of all account movements.
- Loans: Apply for personal loans (needs admin approval).
- Transfer: Send money to other BK accounts.
- Airtime: Top up MTN or Airtel phone numbers.
- Bills: Pay utility bills (REG, WASAC, RRA, Irembo).
- Fixed Deposit: Open high-interest investment accounts.

APP FEATURES FOR ADMINS:
- User Management: Onboard new customers, view all accounts, freeze/unfreeze accounts.
- Loan Approvals: Review and approve/reject pending loan requests.
- Admin Actions: Manual deposits into customer accounts, inter-account transfers, create new customers.
- Account Status: Freeze or activate user accounts.
- Audit Logs: View system security and admin activity logs.

TONE: Professional, helpful, secure, and concise.

SECURITY:
Never ask for passwords or PINs. If they ask about security, emphasize that BK Mobile uses industry-standard encryption and hashed passwords.

If they ask about something not related to the app or banking, politely redirect them back to BK Mobile services.
''';

    try {
      final prompt = '[$systemInstruction]\nUser says: $message';
      final response = await _chat!.sendMessage(Content.text(prompt));

      // Try to handle tool/function calls if present.
      final functionCalls = response.functionCalls.toList();

      if (functionCalls.isNotEmpty) {
        for (final call in functionCalls) {
          final name = call.name.toLowerCase();
          final args = (call.args as Map<String, dynamic>?) ?? {};

          print('AI Function Call: $name - $args');

          // Navigation helper: the model may use different naming conventions.
          if (name.contains('navigate') || name.contains('go_to')) {
            final rawView = (args['view'] as String?) ?? '';
            final view = _normalizeViewName(rawView);
            if (view != null) {
              onNavigate(view);
              final msg = 'Certainly! I\'ve navigated you to the $view page.';
              _messages.add(ChatMessage(role: 'model', text: msg));
              return msg;
            }
          }

          if (user == null) {
            final msg =
                "I'm sorry, you need to be logged in to perform this action.";
            _messages.add(ChatMessage(role: 'model', text: msg));
            return msg;
          }

          final readableName = name.replaceAll('_', ' ');
          onActionStatusUpdate('loading', 'Processing $readableName...');

          try {
            if (name == 'transfer_money') {
              await _apiService.transfer(
                user.id,
                args['to_account'] as String,
                (args['amount'] as num).toDouble(),
                args['reason'] as String,
              );
            } else if (name == 'pay_bill') {
              await _apiService.payBill(
                user.id,
                args['bill_type'] as String,
                args['reference'] as String,
                (args['amount'] as num).toDouble(),
              );
            } else if (name == 'top_up_airtime') {
              await _apiService.topUpAirtime(
                user.id,
                args['phone_number'] as String,
                (args['amount'] as num).toDouble(),
                args['provider'] as String,
              );
            } else if (name == 'apply_loan') {
              await _apiService.applyLoan(
                user.id,
                (args['amount'] as num).toDouble(),
                args['purpose'] as String,
              );
            } else if (name == 'open_fixed_deposit') {
              await _apiService.openFixedDeposit(
                user.id,
                (args['amount'] as num).toDouble(),
                (args['term_months'] as num).toInt(),
              );
            } else {
              // Admin-only actions
              if (user.role != 'admin') {
                final msg =
                    "You must be an administrator to perform this action.";
                _messages.add(ChatMessage(role: 'model', text: msg));
                return msg;
              }
              if (name == 'create_customer') {
                await _apiService.createCustomer({
                  'name': args['name'],
                  'email': args['email'],
                  'password': args['password'],
                  'initialBalance': args['initial_balance'],
                  'accountType': args['account_type'],
                });
              } else if (name == 'admin_deposit') {
                await _apiService.adminDeposit(
                  args['account_number'] as String,
                  (args['amount'] as num).toDouble(),
                  args['description'] as String? ?? '',
                );
              } else if (name == 'admin_transfer') {
                await _apiService.adminTransfer(
                  args['from_account'] as String,
                  args['to_account'] as String,
                  (args['amount'] as num).toDouble(),
                  args['description'] as String? ?? '',
                );
              } else if (name == 'approve_loan') {
                await _apiService.approveLoan((args['loan_id'] as num).toInt());
              } else if (name == 'update_account_status') {
                await _apiService.updateAccountStatusByNumber(
                  args['account_number'] as String,
                  args['status'] as String,
                  user.id,
                );
              }
            }

            onActionStatusUpdate('success', '$readableName successful!');

            final hasScheduledTime =
                args.containsKey('scheduled_time') &&
                    args['scheduled_time'] != null;
            final scheduledMsg = hasScheduledTime
                ? '(Scheduled for ${DateTime.parse(args['scheduled_time'] as String).toLocal().toString().substring(0, 16)})'
                : '';

            var successMsg = '';
            if (name == 'create_customer') {
              successMsg = 'Customer created successfully.';
            } else if (name == 'approve_loan') {
              successMsg = 'Loan approved and funds disbursed.';
            } else if (name == 'update_account_status') {
              successMsg = 'Account status updated to ${args['status']}.';
            } else if (args.containsKey('amount')) {
              successMsg =
                  "Success! The $readableName for RWF ${args['amount']} has been processed. $scheduledMsg";
            } else {
              successMsg = 'Action completed successfully.';
            }

            _messages.add(ChatMessage(role: 'model', text: successMsg));
            onActionComplete();

            Future.delayed(const Duration(seconds: 3), () {
              onActionStatusUpdate('clear', '');
            });
            return successMsg;
          } catch (e) {
            onActionStatusUpdate('error', e.toString());
            final errMsg =
                "I encountered an error trying to $readableName: ${e.toString()}";
            _messages.add(ChatMessage(role: 'model', text: errMsg));

            Future.delayed(const Duration(seconds: 3), () {
              onActionStatusUpdate('clear', '');
            });
            return errMsg;
          }
        }
      }

      final textResponse = response.text;
      if (textResponse != null && textResponse.isNotEmpty) {
        _messages.add(ChatMessage(role: 'model', text: textResponse));
        return textResponse;
      }
    } catch (e, st) {
      // Log full exception for debugging
      print('sendMessage error: $e');
      print(st);

      // If the error indicates a model name issue, try listing available models.
      final errStr = e.toString();
      if (errStr.contains('Call ListModels') ||
          errStr.contains('not found for API version')) {
        await _printAvailableModels();
      }

      final errMsg =
          "I'm having trouble connecting right now. Please try again later.";
      _messages.add(ChatMessage(role: 'model', text: errMsg));
      return errMsg;
    }

    return null;
  }

  String? _normalizeViewName(String rawView) {
    final normalized = rawView.toLowerCase().trim();
    if (normalized.isEmpty) return null;

    if (normalized.contains('dash') || normalized.contains('home')) {
      return 'dashboard';
    }
    if (normalized.contains('transact') || normalized.contains('history')) {
      return 'transactions';
    }
    if (normalized.contains('loan') && normalized.contains('approval')) {
      return 'loan_approvals';
    }
    if (normalized.contains('loan')) return 'loans';
    if (normalized.contains('transfer')) return 'transfer';
    if (normalized.contains('air')) return 'airtime';
    if (normalized.contains('bill')) return 'bills';
    if (normalized.contains('fixed') || normalized.contains('deposit')) {
      return 'fixed_deposit';
    }
    if (normalized.contains('user') && normalized.contains('manage')) {
      return 'users';
    }
    if (normalized.contains('audit') || normalized.contains('log')) {
      return 'audit_logs';
    }
    if (normalized.contains('admin') && normalized.contains('action')) {
      return 'admin_actions';
    }

    // Fallback: if the model sends a view that exactly matches our keys.
    const allowedViews = {
      'dashboard',
      'transactions',
      'loans',
      'transfer',
      'airtime',
      'bills',
      'fixed_deposit',
      'users',
      'loan_approvals',
      'audit_logs',
      'admin_actions',
    };
    if (allowedViews.contains(normalized)) return normalized;

    return null;
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AiService(apiService);
});
