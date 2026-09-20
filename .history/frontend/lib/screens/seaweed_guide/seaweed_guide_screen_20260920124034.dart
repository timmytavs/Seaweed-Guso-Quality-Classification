import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/seaweed_data.dart';
import '../../models/seaweed_info.dart';
import '../../providers/seaweed_language_provider.dart';
import '../../widgets/seaweed_guide/seaweed_card.dart';
import 'seaweed_detail_screen.dart';

class SeaweedGuideScreen extends StatefulWidget {
  const SeaweedGuideScreen({super.key});

  @override
  State<SeaweedGuideScreen> createState() =>
      _SeaweedGuideScreenState();
}

class _SeaweedGuideScreenState
    extends State<SeaweedGuideScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SeaweedInfo> _filteredSeaweeds(
    SeaweedLanguage language,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return SeaweedData.seaweeds;
    }

    return SeaweedData.seaweeds.where((seaweed) {
      final scientificName =
          seaweed.scientificName.toLowerCase();

      final localizedName =
          seaweed.getName(language).toLowerCase();

      final englishName =
          seaweed.englishName.toLowerCase();

      final filipinoName =
          seaweed.filipinoName.toLowerCase();

      final bisayaName =
          seaweed.bisayaName.toLowerCase();

      return scientificName.contains(query) ||
          localizedName.contains(query) ||
          englishName.contains(query) ||
          filipinoName.contains(query) ||
          bisayaName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider =
        context.watch<SeaweedLanguageProvider>();

    final language = languageProvider.language;

    final seaweeds =
        _filteredSeaweeds(language);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          _buildControls(
            context,
            language,
          ),

          const SizedBox(height: 28),

          if (seaweeds.isEmpty)
            _buildEmptySearch()
          else
            _buildGrid(seaweeds),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1.5,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: AppColors.primary,
            size: 32,
          ),

          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Seaweed Guide',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Explore seaweed types, scientific names, '
                  'local names, descriptions, habitats, '
                  'identification features, and common uses.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    SeaweedLanguage selectedLanguage,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth < 700;

        final search = TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText:
                'Search by scientific or local name...',
            prefixIcon: const Icon(
              Icons.search,
            ),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
          ),
        );

        final languageSelector =
            _LanguageSelector(
          selectedLanguage: selectedLanguage,
        );

        if (isCompact) {
          return Column(
            children: [
              search,

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerLeft,
                child: languageSelector,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: search,
            ),

            const SizedBox(width: 18),

            languageSelector,
          ],
        );
      },
    );
  }

  Widget _buildGrid(
    List<SeaweedInfo> seaweeds,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columnCount;

        if (width >= 1100) {
          columnCount = 3;
        } else if (width >= 700) {
          columnCount = 2;
        } else {
          columnCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: seaweeds.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio:
                columnCount == 1 ? 1.15 : 0.88,
          ),
          itemBuilder: (context, index) {
            final seaweed = seaweeds[index];

            return SeaweedCard(
              seaweed: seaweed,
              onTap: () {
                _openSeaweedDetails(
                  context,
                  seaweed,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        border: Border.all(
          color: AppColors.disabled,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off,
            size: 54,
            color: AppColors.textMuted,
          ),

          SizedBox(height: 16),

          Text(
            'No Seaweed Found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Try searching using another scientific '
            'name or local name.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openSeaweedDetails(
    BuildContext context,
    SeaweedInfo seaweed,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening ${seaweed.scientificName}',
        ),
        duration: const Duration(
          seconds: 1,
        ),
      ),
    );

    // The actual detail page will be connected
    // in the next file.
  }
}

class _LanguageSelector extends StatelessWidget {
  final SeaweedLanguage selectedLanguage;

  const _LanguageSelector({
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SeaweedLanguage>(
      segments: SeaweedLanguage.values.map(
        (language) {
          return ButtonSegment<SeaweedLanguage>(
            value: language,
            label: Text(
              language.label,
            ),
          );
        },
      ).toList(),
      selected: {
        selectedLanguage,
      },
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }

        context
            .read<SeaweedLanguageProvider>()
            .setLanguage(
              selection.first,
            );
      },
      style: ButtonStyle(
        backgroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (
                states.contains(
                  WidgetState.selected,
                )
            ) {
              return AppColors.primaryDark;
            }

            return AppColors.surface;
          },
        ),
        foregroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (
                states.contains(
                  WidgetState.selected,
                )
            ) {
              return AppColors.primary;
            }

            return AppColors.textSecondary;
          },
        ),
        side:
            WidgetStateProperty.all(
          const BorderSide(
            color: AppColors.disabled,
          ),
        ),
      ),
    );
  }
}