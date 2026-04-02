import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/template_models.dart';

class ApiClient {
  final Dio _dio;
  String? _token;
  String? _username;

  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 120),
          headers: {'Content-Type': 'application/json'},
        ));

  bool get isLoggedIn => _token != null;
  String? get username => _username;

  void _setAuth() {
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  // ──── Auth ────

  Future<Map<String, dynamic>?> login({required String username, required String password}) async {
    final resp = await _dio.post('/api/v1/auth/login', data: {
      'username': username, 'password': password,
    });
    _token = resp.data['token'];
    _username = resp.data['username'];
    _setAuth();
    return resp.data;
  }

  void logout() {
    _token = null;
    _username = null;
    _dio.options.headers.remove('Authorization');
  }

  // ──── Templates ────

  Future<TemplatesTree> getTemplatesTree() async {
    _setAuth();
    final resp = await _dio.get('/api/v1/templates');
    return TemplatesTree.fromJson(resp.data);
  }

  Future<TemplateDetail> getTemplate(String code) async {
    _setAuth();
    final resp = await _dio.get('/api/v1/templates/$code');
    return TemplateDetail.fromJson(resp.data);
  }

  // ──── Generate ────

  Future<Map<String, dynamic>> generateDocument({
    required String templateCode,
    required Map<String, dynamic> answers,
  }) async {
    _setAuth();
    final resp = await _dio.post('/api/v1/generate', data: {
      'template_code': templateCode, 'answers': answers,
    });
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Uint8List> downloadFile(String filename) async {
    _setAuth();
    final resp = await _dio.get('/api/v1/download/$filename',
        options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(resp.data);
  }

  // ──── Documents (history) ────

  Future<List<dynamic>> getRecentDocuments() async {
    _setAuth();
    final resp = await _dio.get('/api/v1/documents/recent');
    return List<dynamic>.from(resp.data['documents'] ?? []);
  }

  Future<List<dynamic>> getAllDocuments({int limit = 50}) async {
    _setAuth();
    final resp = await _dio.get('/api/v1/documents', queryParameters: {'limit': limit});
    return List<dynamic>.from(resp.data['documents'] ?? []);
  }

  Future<Map<String, dynamic>> getDocument(int docId) async {
    _setAuth();
    final resp = await _dio.get('/api/v1/documents/$docId');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> deleteAllDocuments() async {
    _setAuth();
    final resp = await _dio.delete('/api/v1/documents');
    return Map<String, dynamic>.from(resp.data);
  }

  // ──── Defaults ────

  Future<List<String>> getSystemDefaults(String key) async {
    _setAuth();
    final resp = await _dio.get('/api/v1/defaults/system/$key');
    return List<String>.from(resp.data['items'] ?? []);
  }

  // ──── Reports ────

  Future<void> sendReport({required String message, String? page, String? templateCode}) async {
    _setAuth();
    await _dio.post('/api/v1/reports', data: {
      'message': message,
      if (page != null) 'page': page,
      if (templateCode != null) 'template_code': templateCode,
    });
  }
}
