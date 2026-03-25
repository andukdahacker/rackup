import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rackup/features/home/view/home_page.dart';

/// The application's root router configuration.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Create Room'),
    ),
    GoRoute(
      path: '/join',
      builder: (context, state) => const _PlaceholderScreen(title: 'Join Room'),
    ),
  ],
);

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
