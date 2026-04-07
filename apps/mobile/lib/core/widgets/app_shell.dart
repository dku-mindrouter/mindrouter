import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentIndex,
    required this.title,
    required this.child,
    super.key,
  });

  final int currentIndex;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/today');
            return;
          }

          if (index == 1) {
            context.go('/constellation');
            return;
          }

          if (index == 2) {
            context.go('/nudges');
            return;
          }

          context.go('/profile');
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            label: '별자리',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: '위로',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: '나',
          ),
        ],
      ),
    );
  }
}
