import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/transaction.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';

class TransactionsScreen extends StatefulWidget {
  final DataService dataService;

  const TransactionsScreen({super.key, required this.dataService});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final transactions = widget.dataService.getTransactions()
        .where((tx) => _filterType == null || tx.type == _filterType)
        .toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          PopupMenuButton<TransactionType?>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (val) => setState(() => _filterType = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...TransactionType.values.map((type) => PopupMenuItem(
                value: type,
                child: Text(type.name),
              )),
            ],
          ),
        ],
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isPositive = tx.type == TransactionType.monthlyInvestment || 
                                  tx.type == TransactionType.loanRepayment || 
                                  tx.type == TransactionType.interestPayment || 
                                  tx.type == TransactionType.otherIncome;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPositive ? Icons.add_rounded : Icons.remove_rounded,
                      color: isPositive ? AppColors.success : AppColors.error,
                      size: 16,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(tx.memberName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Text(
                        CalculationUtils.formatCurrency(tx.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isPositive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tx.description ?? tx.type.name, style: const TextStyle(fontSize: 12)),
                      Text(CalculationUtils.formatShortDate(tx.date), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
