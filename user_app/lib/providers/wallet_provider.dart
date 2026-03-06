import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import 'package:intl/intl.dart';

class UserWalletNotifier extends Notifier<UserWalletState> {
  @override
  UserWalletState build() {
    // Initial demo data
    return UserWalletState(
      balance: 200.00,
      transactions: [
        WalletTransaction(
          id: '1',
          title: 'Wallet Top-up',
          amount: 500.0,
          date: 'Feb 5, 2026',
          type: 'credit',
          timestamp: DateTime(2026, 2, 5),
        ),
        WalletTransaction(
          id: '2',
          title: 'Ride Payment',
          amount: 180.0,
          date: 'Feb 4, 2026',
          type: 'debit',
          timestamp: DateTime(2026, 2, 4),
        ),
        WalletTransaction(
          id: '3',
          title: 'Cashback',
          amount: 25.0,
          date: 'Feb 3, 2026',
          type: 'credit',
          timestamp: DateTime(2026, 2, 3),
        ),
        WalletTransaction(
          id: '4',
          title: 'Ride Payment',
          amount: 245.0,
          date: 'Feb 2, 2026',
          type: 'debit',
          timestamp: DateTime(2026, 2, 2),
        ),
      ],
    );
  }

  void addMoney(double amount) {
    final now = DateTime.now();
    final newTransaction = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Wallet Top-up',
      amount: amount,
      date: DateFormat('MMM d, yyyy').format(now),
      type: 'credit',
      timestamp: now,
    );

    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [newTransaction, ...state.transactions],
    );
  }

  void withdraw(double amount) {
    if (amount > state.balance) return;

    final now = DateTime.now();
    final newTransaction = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Bank Withdrawal',
      amount: amount,
      date: DateFormat('MMM d, yyyy').format(now),
      type: 'debit',
      timestamp: now,
    );

    state = state.copyWith(
      balance: state.balance - amount,
      transactions: [newTransaction, ...state.transactions],
    );
  }
}

final userWalletProvider = NotifierProvider<UserWalletNotifier, UserWalletState>(
  UserWalletNotifier.new,
);
