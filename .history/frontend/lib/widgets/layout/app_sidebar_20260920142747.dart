import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/classification_record.dart';
import '../../providers/classification_provider.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final classificationProvider =
        context.watch<ClassificationProvider>();

    final records = classificationProvider.records;

    return Container(
      width: 280,
      color: AppColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 28),

          // User / Profile section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(
                  AppRadius.medium,
                ),
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 1.5,
                ),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryDark,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'USER',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Features section
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Features and Processes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _SidebarItem(
            icon: Icons.image_search_outlined,
            label: 'Classify',
            isSelected: selectedIndex == 0,
            onTap: () => onMenuSelected(0),
          ),

          _SidebarItem(
            icon: Icons.menu_book_outlined,
            label: 'Seaweed Guide',
            isSelected: selectedIndex == 1,
            onTap: () => onMenuSelected(1),
          ),

          _SidebarItem(
            icon: Icons.history,
            label: 'History',
            isSelected: selectedIndex == 2,
            onTap: () => onMenuSelected(2),
          ),

          _SidebarItem(
            icon: Icons.history,
            label: 'History',
            isSelected: selectedIndex == 3,
            onTap: () => onMenuSelected(2),
          ),

          const SizedBox(height: 28),

          // History / Records title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'History / Records',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (records.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      records.length.toString(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dynamic record list
          Expanded(
            child: records.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    itemCount: records.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final record = records[index];

                      final isSelected =
                          classificationProvider
                              .selectedRecord
                              ?.id ==
                          record.id;

                      return _HistoryRecordItem(
                        record: record,
                        isSelected: isSelected,
                        onTap: () {
                          context
                              .read<
                                  ClassificationProvider
                              >()
                              .selectRecord(record);

                          onMenuSelected(1);
                        },
                      );
                    },
                  ),
          ),

          // Settings
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: selectedIndex == 2,
            onTap: () => onMenuSelected(2),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      child: Material(
        color: isSelected
            ? AppColors.primaryDark
            : Colors.transparent,
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),

                const SizedBox(width: 14),

                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 22,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                'No saved records yet',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRecordItem extends StatelessWidget {
  final ClassificationRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryRecordItem({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primaryDark
          : Colors.transparent,
      borderRadius: BorderRadius.circular(
        AppRadius.small,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppRadius.small,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppRadius.small,
                  ),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.disabled,
                  ),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayTitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      record.displayDate,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}