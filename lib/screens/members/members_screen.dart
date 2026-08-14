import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/member.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';
import 'member_detail_screen.dart';

class MembersScreen extends StatefulWidget {
  final DataService dataService;

  const MembersScreen({super.key, required this.dataService});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final members = widget.dataService.getMembers().where((m) => 
      m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      m.phone.contains(_searchQuery)
    ).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Group Members'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search members...',
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
      body: members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No members found', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = members[index];
                return _MemberCard(
                  member: member,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetailScreen(
                          dataService: widget.dataService,
                          member: member,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                );
              },
            ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;

  const _MemberCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  member.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(member.phone, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CalculationUtils.formatCurrency(member.monthlyInvestment),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 15),
                  ),
                  const Text('Monthly', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
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
