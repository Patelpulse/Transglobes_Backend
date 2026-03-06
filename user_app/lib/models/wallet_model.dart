import 'package:flutter/foundation.dart';

@immutable
class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final String date;
  final String type; // 'credit' or 'debit'
  final DateTime timestamp;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.timestamp,
  });
}

@immutable
class UserWalletState {
  final double balance;
  final List<WalletTransaction> transactions;
  final bool isLoading;

  const UserWalletState({
    required this.balance,
    required this.transactions,
    this.isLoading = false,
  });

  UserWalletState copyWith({
    double? balance,
    List<WalletTransaction>? transactions,
    bool? isLoading,
  }) {
    return UserWalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
