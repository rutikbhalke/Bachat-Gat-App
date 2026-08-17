import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/transaction.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filterType;
  late Stream<List<AppTransaction>> _activitiesStream;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _activitiesStream = provider.watchRecentActivities();
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<List<AppTransaction>>(
        stream: _activitiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTransactions = snapshot.data ?? [];
          final transactions = allTransactions
              .where((tx) => _filterType == null || tx.type == _filterType)
              .toList();

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }

          return ListView.separated(
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
          );
        }
      ),
    );
  }
}
