import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/member.dart';
import '../../models/loan.dart';
import '../../models/monthly_contribution.dart';
import '../../models/report_models.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../l10n/app_localizations.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> with SingleTickerProviderStateMixin {
  late Member _member;
  late Stream<List<MonthlyContribution>> _contributionsStream;
  late Stream<List<Loan>> _loansStream;
  late TabController _tabController;
  Future<List<MemberLedgerEntry>>? _ledgerFuture;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _tabController = TabController(length: 3, vsync: this);
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _contributionsStream = provider.watchContributions(memberId: _member.id);
    _loansStream = provider.watchLoans(memberId: _member.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BachatGatProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memberProfile),
        actions: [
          IconButton(
            onPressed: () => _showReportDialog(provider, l10n),
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: l10n.generateReceipt,
          ),
          IconButton(
            onPressed: () => _shareMemberProfile(l10n),
            icon: const Icon(Icons.share_rounded),
            tooltip: l10n.shareOnWhatsApp,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') _editMember(provider);
              if (val == 'deactivate') _deactivateMember(provider);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18), const SizedBox(width: 8), Text(l10n.editMember)])),
              PopupMenuItem(value: 'deactivate', child: Row(children: [const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.error), const SizedBox(width: 8), Text(l10n.delete, style: const TextStyle(color: AppColors.error))])),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<MonthlyContribution>>(
        stream: _contributionsStream,
        builder: (context, contributionSnapshot) {
          final contributions = List<MonthlyContribution>.from(contributionSnapshot.data ?? []);
          contributions.sort((a, b) => (b.year * 12 + b.month).compareTo(a.year * 12 + a.month));
          
          final totalInvested = contributions
              .fold<double>(0.0, (sum, i) => sum + i.actualRegularPaid);

          return StreamBuilder<List<Loan>>(
            stream: _loansStream,
            builder: (context, loanSnapshot) {
              final loans = loanSnapshot.data ?? [];
              final activeLoans = loans.where((l) => l.status == LoanStatus.active).toList();
              final outstandingLoan = activeLoans.fold<double>(0.0, (sum, l) => sum + l.pendingPrincipal);
              final currentMonthInterest = activeLoans.fold<double>(
                0.0,
                (sum, l) => sum + CalculationUtils.calculateMonthlyInterest(
                  outstandingPrincipal: l.pendingPrincipal,
                  annualRate: l.interestRate,
                ),
              );

              return Column(
                children: [
                  // --- HEADER PROFILE CARD ---
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                _member.name.isNotEmpty ? _member.name[0].toUpperCase() : 'M',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_member.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(_member.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.joined}: ${CalculationUtils.formatShortDate(_member.joinDate)} • ${l10n.shares}: ${_member.shares} • ${l10n.hafta}: ₹${_member.monthlyContribution.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Summary row
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: l10n.totalSavings,
                                value: CalculationUtils.formatCurrency(totalInvested),
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryTile(
                                label: l10n.activeLoans,
                                value: CalculationUtils.formatCurrency(outstandingLoan),
                                color: outstandingLoan > 0 ? AppColors.error : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryTile(
                                label: l10n.moInterestLabel,
                                value: CalculationUtils.formatCurrency(currentMonthInterest),
                                color: AppColors.interest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tab navigation
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: l10n.collections),
                        Tab(text: l10n.loans),
                        Tab(text: l10n.ledger),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Monthly Collections
                        _buildCollectionsTab(contributions),
                        // Tab 2: Loans Breakdown
                        _buildLoansTab(loans),
                        // Tab 3: Member Ledger
                        _buildLedgerTab(provider),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionsTab(List<MonthlyContribution> contributions) {
    final l10n = AppLocalizations.of(context)!;
    if (contributions.isEmpty) {
      return Center(child: Text(l10n.noCollectionHistoryFound, style: const TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contributions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = contributions[index];
        final isPaid = item.status == ContributionStatus.paid;
        final isPartial = item.status == ContributionStatus.partial;

        String statusLabel = item.status.name.toUpperCase();
        Color statusColor = isPaid ? AppColors.success : (isPartial ? AppColors.warning : AppColors.warning);

        if (item.status == ContributionStatus.pending) {
          final isOverdue = CalculationUtils.isMonthOverdue(
            month: item.month,
            year: item.year,
          );
          if (isOverdue) {
            statusLabel = l10n.overdue;
            statusColor = AppColors.error;
          } else {
            statusLabel = l10n.due;
            statusColor = AppColors.warning;
          }
        } else if (isPaid) {
          statusLabel = l10n.paidStatus.toUpperCase();
          statusColor = AppColors.success;
        } else if (isPartial) {
          statusLabel = l10n.partialStatus.toUpperCase();
          statusColor = AppColors.warning;
        }

        final memberHaftaDue = _member.monthlyContribution > 0 ? _member.monthlyContribution : 1000.0;
        final regularHafta = item.regularHaftaAmount > 0 && item.regularHaftaAmount <= memberHaftaDue
            ? item.regularHaftaAmount
            : memberHaftaDue;

        final totalDisplayAmount = isPaid
            ? (item.paidAmount > 0 ? item.paidAmount : (regularHafta + item.interestAmount + item.loanPrincipalPaid))
            : (regularHafta + item.interestAmount + item.loanPrincipalPaid);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CalculationUtils.getMonthName(item.month, locale: l10n.localeName)} ${item.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isPartial) ...[
                    Text('${l10n.due}: ₹${(regularHafta + item.interestAmount + item.loanPrincipalPaid).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('${l10n.collected}: ₹${item.paidAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                    Text(
                      '${l10n.remaining}: ₹${((regularHafta + item.interestAmount + item.loanPrincipalPaid) - item.paidAmount).clamp(0.0, double.infinity).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error),
                    ),
                  ] else ...[
                    Text('${l10n.hafta}: ₹${regularHafta.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (item.interestAmount > 0)
                      Text('${l10n.interest}: ₹${item.interestAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.interest)),
                    if (item.loanPrincipalPaid > 0)
                      Text('${l10n.principal}: ₹${item.loanPrincipalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                    Text(
                      '${l10n.total}: ${CalculationUtils.formatCurrency(totalDisplayAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoansTab(List<Loan> loans) {
    final l10n = AppLocalizations.of(context)!;
    if (loans.isEmpty) {
      return Center(child: Text(l10n.noLoansIssuedForMember, style: const TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final loan = loans[index];
        final isActive = loan.status == LoanStatus.active;
        final interestMo = CalculationUtils.calculateMonthlyInterest(
          outstandingPrincipal: loan.pendingPrincipal,
          annualRate: loan.interestRate,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.loan}: ₹${loan.originalPrincipal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? AppColors.error : AppColors.textMuted).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? l10n.activeStatus.toUpperCase() : l10n.closedStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.error : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.issued}: ${CalculationUtils.formatShortDate(loan.loanDate)} • ${l10n.rate}: ${loan.interestRate}%/${l10n.perMonth}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.outstandingPrincipal, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      Text(CalculationUtils.formatCurrency(loan.pendingPrincipal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.monthlyInterestLabel, style: const TextStyle(fontSize: 10, color: AppColors.interest, fontWeight: FontWeight.bold)),
                      Text(CalculationUtils.formatCurrency(interestMo), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.interest)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerTab(BachatGatProvider provider) {
    _ledgerFuture ??= provider.getMemberLedger(_member.id);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<MemberLedgerEntry>>(
      future: _ledgerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
                  const SizedBox(height: 8),
                  Text(l10n.failedLoadLedger, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _ledgerFuture = provider.getMemberLedger(_member.id, forceRefresh: true);
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(child: Text(l10n.noLedgerEntries, style: const TextStyle(color: AppColors.textMuted)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (entry.credit > 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      entry.credit > 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      size: 16,
                      color: entry.credit > 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(CalculationUtils.formatShortDate(entry.date), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.credit > 0 ? '+ ${CalculationUtils.formatCurrency(entry.credit)}' : '- ${CalculationUtils.formatCurrency(entry.debit)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: entry.credit > 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        'Bal: ${CalculationUtils.formatCurrency(entry.balance)}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReportDialog(BachatGatProvider provider, AppLocalizations l10n) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.generateReceipt),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(CalculationUtils.getMonthName(i + 1)))),
                onChanged: (val) => setDialogState(() => selectedMonth = val!),
                decoration: InputDecoration(labelText: l10n.month),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                items: [now.year - 1, now.year, now.year + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (val) => setDialogState(() => selectedYear = val!),
                decoration: const InputDecoration(labelText: 'Year'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                _generateAndActionReceipt(provider, l10n, selectedMonth, selectedYear, isShare: false);
              },
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text(l10n.view),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                _generateAndActionReceipt(provider, l10n, selectedMonth, selectedYear, isShare: true);
              },
              icon: const Icon(Icons.share_outlined, size: 16),
              label: Text(l10n.shareOnWhatsApp),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareMemberProfile(AppLocalizations l10n) async {
    await ShareService.openMemberWhatsAppChat(
      member: _member,
      languageCode: l10n.localeName,
      context: context,
    );
  }

  Future<void> _generateAndActionReceipt(BachatGatProvider provider, AppLocalizations l10n, int month, int year, {required bool isShare}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final report = await provider.getMemberReport(_member, month, year);
      final group = await provider.watchGroup().first;
      
      final labels = {
        'groupName': CalculationUtils.resolveGroupName(group?.name, l10n.defaultGroupName),
        'monthlyReceipt': l10n.monthlyReceipt,
        'member': l10n.member,
        'phone': l10n.phone,
        'month': l10n.month,
        'monthlyContribution': l10n.monthlyContribution,
        'regularHafta': l10n.regularHafta,
        'amountPaid': l10n.amountPaid,
        'pending': l10n.pending,
        'loan': l10n.loan,
        'openingLoan': l10n.openingLoan,
        'interestRate': l10n.interestRate,
        'monthlyInterest': l10n.monthlyInterest,
        'loanRepaid': l10n.loanRepaid,
        'closingLoan': l10n.closingLoan,
        'total': l10n.total,
        'totalPaid': l10n.totalPaid,
      };

      final pdfBytes = await PdfService.generateMemberReceiptBytes(
        report: report,
        labels: labels,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (isShare) {
        await ShareService.shareMemberReceipt(
          report: report,
          pdfBytes: pdfBytes,
          languageCode: l10n.localeName,
        );
      } else {
        await Printing.layoutPdf(
          name: 'BG_Receipt_${_member.name}_${month}_$year.pdf',
          onLayout: (format) async => pdfBytes,
        );
      }
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editMember(BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: _member.name);
    final phoneController = TextEditingController(text: _member.phone);
    final sharesController = TextEditingController(text: _member.shares.toString());
    final perShareController = TextEditingController(text: _member.monthlyContributionPerShare.toStringAsFixed(0));
    String? errorMessage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final shares = int.tryParse(sharesController.text) ?? _member.shares;
          final perShare = double.tryParse(perShareController.text) ?? _member.monthlyContributionPerShare;
          final totalMonthly = CalculationUtils.calculateMemberMonthlyHafta(
            shares: shares,
            contributionPerShare: perShare,
          );

          return AlertDialog(
            title: Text(l10n.updateMember),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.memberName)),
                  const SizedBox(height: 12),
                  TextField(controller: phoneController, decoration: InputDecoration(labelText: l10n.mobileNumber)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sharesController,
                          decoration: InputDecoration(labelText: l10n.sharesCount),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() => errorMessage = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: perShareController,
                          decoration: InputDecoration(labelText: '${l10n.perShare} (₹)'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() => errorMessage = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${l10n.monthlyContribution}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          CalculationUtils.formatCurrency(totalMonthly),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final parsedShares = int.tryParse(sharesController.text);
                        if (parsedShares == null || parsedShares < 1) {
                          setDialogState(() => errorMessage = 'Shares must be at least 1.');
                          return;
                        }
                        final parsedPerShare = double.tryParse(perShareController.text);
                        if (parsedPerShare == null || parsedPerShare < 0) {
                          setDialogState(() => errorMessage = 'Contribution per share must be valid.');
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final newMember = _member.copyWith(
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            shares: parsedShares,
                            monthlyContributionPerShare: parsedPerShare,
                            monthlyContribution: parsedShares * parsedPerShare,
                            updatedAt: DateTime.now(),
                          );
                          
                          await provider.updateMember(newMember);
                          if (!context.mounted) return;
                          setState(() => _member = newMember);
                          Navigator.pop(context);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deactivateMember(BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deactivateMember),
        content: Text(l10n.deactivateConfirm(_member.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              await provider.deactivateMember(_member.id);
              if (!context.mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to members list
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
