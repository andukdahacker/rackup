import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The application's root router configuration.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderHome(),
    ),
  ],
);

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Rackup')),
    );
  }
}
