import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/seaweed_data.dart';
import '../../models/seaweed_info.dart';
import '../../widgets/seaweed_guide/seaweed_card.dart';
import '../../widgets/common/empty_state.dart';
import 'seaweed_detail_screen.dart';

class SeaweedGuideScreen extends StatefulWidget {
  const SeaweedGuideScreen({super.key});

  @override
  State<SeaweedGuideScreen> createState() => _SeaweedGuideScreenState();
}

class _SeaweedGuideScreenState extends State<SeaweedGuideScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedLanguage = 'English';

  final List<String> _languages = const [
    'English',
    'Filipino',
    'Bisaya',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSeaweeds = _getFilteredSeaweeds();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildHeader(context),
              const SizedBox(height: AppSpacing.lg),

              _buildIntroCard(context),
              const SizedBox(height: AppSpacing.lg),

              _buildSearchField(),
              const SizedBox(height: AppSpacing.md),

              _buildLanguageSelector(),
              const SizedBox(height: AppSpacing.lg),

              if (filteredSeaweeds.isEmpty)
                _buildEmptyState(context)
              else
                _buildSeaweedList(
                  context,
                  filteredSeaweeds,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<SeaweedInfo> _getFilteredSeaweeds() {
    final query = _searchController.text;

    return SeaweedData.seaweeds.where((seaweed) {
      return seaweed.matchesSearch(
        query,
        _selectedLanguage,
      );
    }).toList();
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: AppColors.primary,
            ),
          ),
          child: const Icon(
            Icons.menu_book_outlined,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seaweed Guide',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore supported seaweed species and learn their basic characteristics.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() {});
      },
      style: const TextStyle(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search seaweed species...',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
        ),
        prefixIcon: const Icon(
          Icons.search_outlined,
          color: AppColors.textMuted,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textMuted,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        children: _languages.map((language) {
          final isSelected = _selectedLanguage == language;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLanguage = language;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary,
                        )
                      : null,
                ),
                child: Text(
                  language,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.eco_outlined,
            color: AppColors.primary,
            size: 21,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Browse supported seaweed species, search by name, and switch the guide language.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeaweedList(
    BuildContext context,
    List<SeaweedInfo> seaweeds,
  ) {
    return Column(
      children: seaweeds.map((seaweed) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.sm,
          ),
          child: SeaweedCard(
            seaweed: seaweed,
            language: _selectedLanguage,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SeaweedDetailScreen(
                    seaweed: seaweed,
                    language: _selectedLanguage,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'No seaweed found',
      message: 'Try another search term.',
      actionLabel: 'Clear Search',
      actionIcon: Icons.clear,
      onAction: () {
        _searchController.clear();

        setState(() {});
      },
    );
  }
}