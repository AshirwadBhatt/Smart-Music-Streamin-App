import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../features/player/presentation/providers/player_provider.dart';
import 'mini_player.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _locationToIndex(String loc) {
    if (loc.startsWith('/search'))  return 1;
    if (loc.startsWith('/library')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location  = GoRouterState.of(context).matchedLocation;
    final idx       = _locationToIndex(location);
    final hasSong   = ref.watch(currentSongProvider) != null;
    // When mini player is visible, add extra bottom padding so content isn't hidden
    final extraPad  = hasSong ? AppConstants.miniPlayerHeight + 12 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // Content with padding so it's never hidden behind mini player
        Padding(
          padding: EdgeInsets.only(bottom: extraPad),
          child: child,
        ),
        // Mini player sits just above the bottom nav bar
        Positioned(
          left: 0, right: 0,
          bottom: AppConstants.bottomNavHeight,
          child: const MiniPlayer(),
        ),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: NavigationBar(
          height: AppConstants.bottomNavHeight,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          selectedIndex: idx,
          onDestinationSelected: (i) {
            const routes = ['/home', '/search', '/library', '/profile'];
            context.go(routes[i]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music_rounded, color: AppColors.primary),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }
}
