import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient(baseUrl: Uri.base.origin);

  runApp(
    RepositoryProvider<ApiClient>.value(
      value: apiClient,
      child: const DocGeneratorApp(),
    ),
  );
}
