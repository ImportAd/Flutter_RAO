import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../core/api/api_client.dart';
import '../features/login/view/login_page.dart';
import '../features/home/view/home_page.dart';
import '../features/fill/view/fill_page.dart';
import '../features/success/view/success_page.dart';
import '../features/documents/view/documents_page.dart';

GoRouter _createRouter(ApiClient api) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = api.isLoggedIn;
      final isLogin = state.uri.path == '/login';
      if (!loggedIn && !isLogin) return '/login';
      if (loggedIn && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/fill/:code',
        builder: (_, state) {
          final code = state.pathParameters['code']!;
          final fromDoc = state.uri.queryParameters['fromDoc'];
          return FillPage(templateCode: code, fromDocId: fromDoc != null ? int.tryParse(fromDoc) : null);
        },
      ),
      GoRoute(
        path: '/success',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SuccessPage(
            templateTitle: extra['title'] as String? ?? '',
            templateCode: extra['code'] as String? ?? '',
            filename: extra['filename'] as String?,
            aktFilename: extra['akt_filename'] as String?,
            edoFilename: extra['edo_filename'] as String?,
          );
        },
      ),
      GoRoute(path: '/documents', builder: (_, __) => const DocumentsPage()),
    ],
  );
}

class DocGeneratorApp extends StatelessWidget {
  const DocGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return MaterialApp.router(
      title: 'Генератор документов',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _createRouter(api),
    );
  }
}
