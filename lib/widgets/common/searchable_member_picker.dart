import 'package:flutter/material.dart';
import 'package:bachat_gat/app/app_colors.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';
import 'package:bachat_gat/l10n/app_localizations.dart';
import 'package:bachat_gat/models/member.dart';

class SearchableMemberPicker extends StatefulWidget {
  final List<Member> pendingMembers;
  final Map<String, double> pendingAmounts;
  final Member? initiallySelected;

  const SearchableMemberPicker({
    super.key,
    required this.pendingMembers,
    required this.pendingAmounts,
    this.initiallySelected,
  });

  static Future<Member?> show({
    required BuildContext context,
    required List<Member> pendingMembers,
    required Map<String, double> pendingAmounts,
    Member? initiallySelected,
  }) {
    return showDialog<Member>(
      context: context,
      builder: (dialogContext) => SearchableMemberPicker(
        pendingMembers: pendingMembers,
        pendingAmounts: pendingAmounts,
        initiallySelected: initiallySelected,
      ),
    );
  }

  @override
  State<SearchableMemberPicker> createState() => _SearchableMemberPickerState();
}

class _SearchableMemberPickerState extends State<SearchableMemberPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final filtered = widget.pendingMembers.where((m) {
      if (_query.isEmpty) return true;
      final cleanPhone = m.phone.replaceAll(RegExp(r'\D'), '');
      return m.name.toLowerCase().contains(_query) || cleanPhone.contains(_query);
    }).toList();

    final sortedMembers = CalculationUtils.sortMembersByBaseNameAndSequence(filtered);

    final notFoundLabel = l10n.localeName == 'mr'
        ? 'सभासद सापडला नाही'
        : l10n.noMembersFound;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  l10n.selectMember,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.pendingMembers.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            // Top Fixed Search Bar
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.searchMembers,
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 10),
            // Member List
            Expanded(
              child: sortedMembers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            notFoundLabel,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: sortedMembers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final m = sortedMembers[index];
                        final remaining = widget.pendingAmounts[m.id] ?? m.monthlyContribution;
                        final isSelected = widget.initiallySelected?.id == m.id;

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              m.name.isNotEmpty ? m.name[0] : 'M',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            m.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: m.phone.isNotEmpty
                              ? Text(m.phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '₹${remaining.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.pop(context, m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
