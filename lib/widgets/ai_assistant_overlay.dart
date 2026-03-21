import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/auth_provider.dart';
import '../services/ai_service.dart';
import '../screens/main_layout.dart';
import '../screens/transactions_screen.dart';
import '../screens/user/user_loans_screen.dart';
import '../screens/transfer_screen.dart';
import '../screens/user/airtime_top_up_screen.dart' as user_airtime;
import '../screens/user/pay_bills_screen.dart' as user_bills;
import '../screens/user/fixed_deposit_screen.dart' as user_fd;
import '../screens/admin/user_management_screen.dart' as admin_users;
import '../screens/admin/loan_approvals_screen.dart' as admin_loans;
import '../screens/admin/audit_logs_screen.dart' as admin_logs;
import '../screens/admin/admin_actions_screen.dart' as admin_actions;

class AiAssistantOverlay extends ConsumerStatefulWidget {
  const AiAssistantOverlay({super.key});

  @override
  ConsumerState<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends ConsumerState<AiAssistantOverlay> {
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _actionStatusType;
  String? _actionStatusMessage;

  final List<String> _quickQuestions = [
    "How do I apply for a loan?",
    "What are the fixed deposit rates?",
    "How can I pay my electricity bill?",
    "Where can I see my transaction history?",
    "Go to the dashboard",
    "Show me my loans",
    "Take me to user management",
    "Approve pending loans",
  ];

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final aiService = ref.read(aiServiceProvider);
    final user = ref.read(authProvider).user;
    final account = ref.read(authProvider).account;

    setState(() {
      _isLoading = true;
      _inputController.clear();
      _actionStatusType = null;
      _actionStatusMessage = null;
    });

    _scrollToBottom();

    await aiService.sendMessage(
      message: text,
      user: user,
      account: account,
      currentView: 'Dashboard', // Should dynamically pass this if using router
      onNavigate: (view) {
        // Basic navigation logic based on view name
        Navigator.of(context).pop(); // close overlay first
        switch (view) {
          case 'dashboard':
            // go back to main layout home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
            break;
          case 'transactions':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            );
            break;
          case 'loans':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserLoansScreen()),
            );
            break;
          case 'transfer':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransferScreen()),
            );
            break;
          case 'airtime':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const user_airtime.AirtimeTopUpScreen()),
            );
            break;
          case 'bills':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const user_bills.PayBillsScreen()),
            );
            break;
          case 'fixed_deposit':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const user_fd.FixedDepositScreen()),
            );
            break;
          case 'users':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const admin_users.UserManagementScreen()),
            );
            break;
          case 'loan_approvals':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const admin_loans.LoanApprovalsScreen()),
            );
            break;
          case 'audit_logs':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const admin_logs.AuditLogsScreen()),
            );
            break;
          case 'admin_actions':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const admin_actions.AdminActionsScreen()),
            );
            break;
          default:
            // unknown view
            break;
        }
      },
      onActionComplete: () {
        // Refresh account or transactions here
        ref.read(authProvider.notifier).refreshAccount();
      },
      onActionStatusUpdate: (type, message) {
        if (mounted) {
          setState(() {
            if (type == 'clear') {
              _actionStatusType = null;
              _actionStatusMessage = null;
            } else {
              _actionStatusType = type;
              _actionStatusMessage = message;
            }
          });
          _scrollToBottom();
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiService = ref.watch(aiServiceProvider);
    final messages = aiService.messages;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle/Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF004A99),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BK Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Always here to help',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Chat list
            Container(
              color: Colors.grey.shade50,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                itemCount:
                    messages.length +
                    (_isLoading ? 1 : 0) +
                    (_actionStatusMessage != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    final isUser = messages[index].role == 'user';
                    return _buildMessageBubble(isUser, messages[index].text);
                  } else if (index == messages.length && _isLoading) {
                    return _buildLoadingBubble();
                  } else {
                    return _buildActionStatusBubble();
                  }
                },
              ),
            ),

          // Quick Actions
          if (messages.length < 3 && !_isLoading)
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ).copyWith(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickQuestions
                    .map(
                      (q) => ActionChip(
                        label: Text(
                          q,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onPressed: () {
                          _inputController.text = q;
                        },
                      ),
                    )
                    .toList(),
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF004A99),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF004A99),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Powered by BK Intelligence',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      )
  );}

  Widget _buildMessageBubble(bool isUser, String message) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF004A99) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : const Radius.circular(0),
          ),
          border: isUser ? null : Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: isUser
            ? Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : MarkdownBody(
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.black87, fontSize: 14),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            16,
          ).copyWith(bottomLeft: const Radius.circular(0)),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF004A99),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionStatusBubble() {
    if (_actionStatusType == null || _actionStatusMessage == null)
      return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData iconData;

    if (_actionStatusType == 'success') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      borderColor = Colors.green.shade100;
      iconData = Icons.check_circle;
    } else if (_actionStatusType == 'error') {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      borderColor = Colors.red.shade100;
      iconData = Icons.error;
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      borderColor = Colors.blue.shade100;
      iconData = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_actionStatusType == 'loading')
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(iconData, size: 16, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _actionStatusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
