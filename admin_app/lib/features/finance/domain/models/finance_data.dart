import 'package:equatable/equatable.dart';

enum TransactionStatus { pending, success, failed }

enum ServiceType { cab, truck, bus }

class Transaction extends Equatable {
  final String id;
  final ServiceType type;
  final double amount;
  final DateTime date;
  final TransactionStatus status;
  final String serviceDesc;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    required this.serviceDesc,
  });

  @override
  List<Object?> get props => [id, type, amount, date, status, serviceDesc];
}

class FinancialMetrics extends Equatable {
  final double totalCommission;
  final double growthPercentage;
  final double pendingPayouts;
  final int activePayouts;
  final int successfulTransactions;
  final double transactionGrowth;
  final List<double> weeklyEarnings;

  const FinancialMetrics({
    required this.totalCommission,
    required this.growthPercentage,
    required this.pendingPayouts,
    required this.activePayouts,
    required this.successfulTransactions,
    required this.transactionGrowth,
    required this.weeklyEarnings,
  });

  @override
  List<Object?> get props => [
    totalCommission,
    growthPercentage,
    pendingPayouts,
    activePayouts,
    successfulTransactions,
    transactionGrowth,
    weeklyEarnings,
  ];
}
