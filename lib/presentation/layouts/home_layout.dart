import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';

// NOTE: FilesTabWithRouter is no longer needed with go_router's StatefulShellRoute.
// The shell injects a StatefulNavigationShell that manages per-branch Navigators.

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Renders the active branch's Navigator (keeps each tab's back stack/state)
      body: navigationShell,
      bottomNavigationBar: Builder(
        builder: (context) {
          final t = AppLocalizations.of(context);
          return NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: t.t('app_nav_home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.folder_open_outlined),
                selectedIcon: const Icon(Icons.folder),
                label: t.t('app_nav_files'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: t.t('app_nav_settings'),
              ),
            ],
          );
        },
      ),
    );
  }
}
