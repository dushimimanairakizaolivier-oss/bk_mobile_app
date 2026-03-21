import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/account.dart';
import '../services/api_service.dart';

class AuthState {
  final User? user;
  final Account? account;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.account,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    Account? account,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(apiServiceProvider).login(email, password);
      state = AuthState(
        user: result['user'] as User,
        account: result['account'] as Account?,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> refreshAccount() async {
    final user = state.user;
    if (user != null) {
      try {
        final account = await ref.read(apiServiceProvider).getAccount(user.id);
        state = state.copyWith(account: account);
      } catch (e) {
        // Silently fail or log for refresh failures
      }
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
