import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/audit_log.dart';
import '../../services/api_service.dart';

final auditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  return ref.read(apiServiceProvider).getAuditLogs();
});

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(auditLogsProvider),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No audit logs found.'));
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isFreeze = log.action.contains('frozen');
              final isUnfreeze = log.action.contains('active');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isFreeze
                      ? Colors.red.withAlpha(50)
                      : isUnfreeze
                          ? Colors.green.withAlpha(50)
                          : Theme.of(context).primaryColor.withAlpha(50),
                  child: Icon(
                    isFreeze
                        ? Icons.lock
                        : isUnfreeze
                            ? Icons.lock_open
                            : Icons.security,
                    color: isFreeze
                        ? Colors.red
                        : isUnfreeze
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(log.details, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                    'Admin ID: ${log.adminId} • ${log.adminName ?? 'Unknown'} • ${log.createdAt?.substring(0, 16) ?? ''}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading logs: $e')),
      ),
    );
  }
}
