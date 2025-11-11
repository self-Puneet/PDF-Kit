import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:pdf_kit/presentation/pages/setting_page.dart';
import 'package:pdf_kit/core/app_export.dart';

// FilesTabWithRouter (or FilesTab) widget
class FilesTabWithRouter extends StatelessWidget {
  const FilesTabWithRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent outer navigator from popping first
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final popped = await AppRouter.filesNavKey.currentState?.maybePop() ?? false;
        if (!popped) {
          // allow outer navigator to handle pop if inner can't
          Navigator.of(context).maybePop();
        }
      },
      child: Navigator(
        key: AppRouter.filesNavKey,
        onGenerateRoute: AppRouter.onGenerateFilesRoute,
        initialRoute: '/', // FilesRoutes.root
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  final _tabs = const [
    HomeTab(),
    FilesTabWithRouter(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
