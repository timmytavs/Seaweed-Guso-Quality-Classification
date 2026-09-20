import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../screens/classification/classification_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/settings/settings_screen.dart';
import 'app_sidebar.dart';
import '../../screens/seaweed_guide/seaweed_guide_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({
    super.key,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;

  static const double _desktopBreakpoint = 1000;

  void _handleMenuSelected(
    int index, {
    bool closeDrawer = false,
  }) {
    setState(() {
      _selectedIndex = index;
    });

    if (closeDrawer) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 1:
        return const HistoryScreen();

      case 2:
        return const SettingsScreen();

      case 0:
      default:
        return const ClassificationScreen();
    }
  }

  String _currentPageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'History';

      case 2:
        return 'Settings';

      case 0:
      default:
        return 'Classify';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= _desktopBreakpoint;

        if (isDesktop) {
          return _buildDesktopLayout();
        }

        return _buildCompactLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: _selectedIndex,
            onMenuSelected: (index) {
              _handleMenuSelected(index);
            },
          ),

          Expanded(
            child: Container(
              color: AppColors.background,
              child: SafeArea(
                child: _buildCurrentPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,

      drawer: Drawer(
        width: 280,
        backgroundColor: AppColors.sidebar,
        child: SafeArea(
          child: AppSidebar(
            selectedIndex: _selectedIndex,
            onMenuSelected: (index) {
              _handleMenuSelected(
                index,
                closeDrawer: true,
              );
            },
          ),
        ),
      ),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.sidebar,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 4,
        title: Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                children: [
                  TextSpan(
                    text: 'g',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'US',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Container(
              width: 1,
              height: 20,
              color: AppColors.disabled,
            ),

            const SizedBox(width: 12),

            Text(
              _currentPageTitle(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Container(
          width: double.infinity,
          color: AppColors.background,
          child: _buildCurrentPage(),
        ),
      ),
    );
  }
}