import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();

//   final apiClient = ApiClient(baseUrl: Uri.base.origin);

//   runApp(
//     RepositoryProvider<ApiClient>.value(
//       value: apiClient,
//       child: const DocGeneratorApp(),
//     ),
//   );
// }

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final resolvedBaseUrl =
      apiBaseUrl.isNotEmpty ? apiBaseUrl : Uri.base.origin;

  final apiClient = ApiClient(baseUrl: resolvedBaseUrl);

  runApp(
    RepositoryProvider<ApiClient>.value(
      value: apiClient,
      child: const DocGeneratorApp(),
    ),
  );
}