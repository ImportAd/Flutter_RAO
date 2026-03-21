import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/template_models.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ));

  /// Получить дерево шаблонов
  Future<TemplatesTree> getTemplatesTree() async {
    final resp = await _dio.get('/api/v1/templates');
    return TemplatesTree.fromJson(resp.data);
  }

  /// Получить структуру конкретного шаблона
  Future<TemplateDetail> getTemplate(String code) async {
    final resp = await _dio.get('/api/v1/templates/$code');
    return TemplateDetail.fromJson(resp.data);
  }

  /// Сгенерировать документ — возвращает байты DOCX
  Future<Uint8List> generateDocument({
    required String templateCode,
    required Map<String, dynamic> answers,
  }) async {
    final resp = await _dio.post(
      '/api/v1/generate',
      data: {
        'template_code': templateCode,
        'answers': answers,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resp.data);
  }

  /// Получить системные дефолты
  Future<List<String>> getSystemDefaults(String key) async {
    final resp = await _dio.get('/api/v1/defaults/system/$key');
    return List<String>.from(resp.data['items'] ?? []);
  }

  /// Получить пользовательские дефолты
  Future<List<String>> getUserDefaults(String key) async {
    final resp = await _dio.get('/api/v1/defaults/user/$key');
    return List<String>.from(resp.data['items'] ?? []);
  }
}
