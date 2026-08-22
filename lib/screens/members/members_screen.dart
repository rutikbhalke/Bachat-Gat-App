import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/member.dart';
import '../../models/monthly_contribution.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';
import 'member_detail_screen.dart';

enum MemberListMode {
  all,
  pending,
}

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _searchQuery = '';
  MemberListMode _selectedMode = MemberListMode.all;
  late Stream<List<Member>> _membersStream;
  late Stream<List<MonthlyContribution>> _contributionsStream;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _membersStream = provider.watchMembers(activeOnly: true);
    _contributionsStream = provider.watchContributions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.groupMembers),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: l10n.searchMembers,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                fillColor: AppColors.background,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Member>>(
        stream: _membersStream,
        builder: (context, memberSnapshot) {
          if (memberSnapshot.connectionState == ConnectionState.waiting && !memberSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<MonthlyContribution>>(
            stream: _contributionsStream,
            builder: (context, contribSnapshot) {
              final members = memberSnapshot.data ?? [];
              final contributions = contribSnapshot.data ?? [];

              final now = DateTime.now();
              final activeCycle = CalculationUtils.getActiveCycleForDate(now, dueDay: 10);
              final currentMonth = activeCycle.month;
              final currentYear = activeCycle.year;
              final allActiveMembers = CalculationUtils.sortMembersByBaseNameAndSequence(
                members.where((m) => m.status == MemberStatus.active).toList(),
              );

              // Map current cycle's contributions by memberId
              final currentMonthContribsByMember = <String, MonthlyContribution>{};
              for (final c in contributions) {
                if (c.month == currentMonth && c.year == currentYear) {
                  currentMonthContribsByMember[c.memberId] = c;
                }
              }

              // Compute pending amounts for all active members
              final pendingAmounts = <String, double>{};
              final rawPendingMembers = <Member>[];

              for (final member in allActiveMembers) {
                final contrib = currentMonthContribsByMember[member.id];
                final remaining = CalculationUtils.calculateMemberPendingHafta(
                  member: member,
                  contribution: contrib,
                );

                if (remaining > 0) {
                  pendingAmounts[member.id] = remaining;
                  rawPendingMembers.add(member);
                }
              }

              final pendingMembers = CalculationUtils.sortMembersByBaseNameAndSequence(rawPendingMembers);

              // Filter members based on selected tab and search query
              final membersToFilter = _selectedMode == MemberListMode.all
                  ? allActiveMembers
                  : pendingMembers;

              final filtered = membersToFilter.where((m) =>
                m.name.toLowerCase().contains(_searchQuery) ||
                m.phone.contains(_searchQuery)
              ).toList();

              final displayedMembers = CalculationUtils.sortMembersByBaseNameAndSequence(filtered);

              return Column(
                children: [
                  // Selectable Tabs / Toggle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              label: l10n.allMembers,
                              count: allActiveMembers.length,
                              isSelected: _selectedMode == MemberListMode.all,
                              selectedColor: AppColors.primary,
                              onTap: () {
                                if (_selectedMode != MemberListMode.all) {
                                  setState(() => _selectedMode = MemberListMode.all);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTabButton(
                              label: l10n.pendingDues,
                              count: pendingMembers.length,
                              isSelected: _selectedMode == MemberListMode.pending,
                              selectedColor: AppColors.error,
                              onTap: () {
                                if (_selectedMode != MemberListMode.pending) {
                                  setState(() => _selectedMode = MemberListMode.pending);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Single Member List
                  Expanded(
                    child: displayedMembers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedMode == MemberListMode.pending
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.people_outline_rounded,
                                  size: 64,
                                  color: _selectedMode == MemberListMode.pending
                                      ? AppColors.success.withValues(alpha: 0.5)
                                      : AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedMode == MemberListMode.pending
                                      ? (_searchQuery.isNotEmpty ? l10n.noPendingMembersMatch : l10n.allCollectionsUpToDate)
                                      : l10n.noMembersFound,
                                  style: TextStyle(
                                    color: _selectedMode == MemberListMode.pending && _searchQuery.isEmpty
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: _selectedMode == MemberListMode.pending && _searchQuery.isEmpty
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: displayedMembers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final member = displayedMembers[index];
                              final isPendingTab = _selectedMode == MemberListMode.pending;
                              return _MemberCard(
                                member: member,
                                isPending: isPendingTab,
                                pendingAmount: pendingAmounts[member.id],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemberDetailScreen(
                                        member: member,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
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

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : selectedColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected ? Colors.white : selectedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;
  final bool isPending;
  final double? pendingAmount;

  const _MemberCard({
    required this.member,
    required this.onTap,
    this.isPending = false,
    this.pendingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: (isPending ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPending ? AppColors.error : AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CalculationUtils.formatCurrency(
                      isPending ? (pendingAmount ?? member.monthlyContribution) : member.monthlyContribution,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isPending ? AppColors.error : AppColors.success,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    isPending ? l10n.pending : l10n.monthly,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isPending ? AppColors.error : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
