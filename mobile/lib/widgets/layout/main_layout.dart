import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/classification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/classification/classification_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/seaweed_guide/seaweed_guide_screen.dart';
import '../../screens/settings/settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ClassificationScreen(),
    SeaweedGuideScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  Future<void> _onDestinationSelected(
    int index,
  ) async {
    if (index == _selectedIndex) {
      return;
    }

    final classificationProvider =
        context.read<ClassificationProvider>();

    final settingsProvider =
        context.read<SettingsProvider>();

    final leavingClassification =
        _selectedIndex == 0 && index != 0;

    final shouldConfirmDiscard =
        leavingClassification &&
        classificationProvider.hasUnsavedResult &&
        settingsProvider.confirmBeforeDiscard;

    if (shouldConfirmDiscard) {
      final shouldDiscard =
          await _showDiscardDialog();

      if (!mounted || shouldDiscard != true) {
        return;
      }

      classificationProvider
          .discardCurrentResult();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Discard classification?',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'You have an unsaved classification result. '
            'Leaving this page will discard the current result.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Stay',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Discard',
                style: TextStyle(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(
            top: BorderSide(
              color: AppColors.borderLight,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected:
                _onDestinationSelected,
            backgroundColor:
                AppColors.surfaceDark,
            indicatorColor:
                AppColors.primaryDark,
            labelBehavior:
                NavigationDestinationLabelBehavior
                    .alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.image_search_outlined,
                  color:
                      AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.image_search,
                  color: AppColors.primary,
                ),
                label: 'Classify',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.menu_book_outlined,
                  color:
                      AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.menu_book,
                  color: AppColors.primary,
                ),
                label: 'Guide',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.history_outlined,
                  color:
                      AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.history,
                  color: AppColors.primary,
                ),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                  color:
                      AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.settings,
                  color: AppColors.primary,
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}