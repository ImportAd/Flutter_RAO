import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../features/home/view/home_page.dart';
import '../features/fill/view/fill_page.dart';
import '../features/success/view/success_page.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/fill/:code',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        return FillPage(templateCode: code);
      },
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SuccessPage(
          templateTitle: extra?['title'] as String? ?? '',
          templateCode: extra?['code'] as String? ?? '',
        );
      },
    ),
  ],
);

class DocGeneratorApp extends StatelessWidget {
  const DocGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Генератор документов',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
