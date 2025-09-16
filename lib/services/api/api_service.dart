import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';
import '../auth/auth_service.dart';

// Types d'erreurs API
enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  validation,
  rateLimit,
  unknown,
}

// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException: $message (${type.name})';
}

// Réponse API standardisée
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? metadata;
  final List<String>? errors;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.metadata,
    this.errors,
  });

  factory ApiResponse.success(
    T data, {
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      metadata: metadata,
    );
  }

  factory ApiResponse.error(String message, {List<String>? errors}) {
    return ApiResponse(success: false, message: message, errors: errors);
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return ApiResponse(
      success: json['success'] ?? true,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'],
      metadata: json['metadata'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }
}

// Service API centralisé
class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  final http.Client _client = http.Client();
  final AuthService _authService = AuthService.instance;

  // Configuration par défaut
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers avec authentification
  Map<String, String> get _authHeaders {
    final headers = Map<String, String>.from(_defaultHeaders);

    final session = _authService.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    return headers;
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final mergedHeaders = {..._authHeaders, ...?headers};

      final response = await _client
          .get(uri, headers: mergedHeaders)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._authHeaders, ...?headers};
      final jsonBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .post(uri, headers: mergedHeaders, body: jsonBody)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._authHeaders, ...?headers};
      final jsonBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .put(uri, headers: mergedHeaders, body: jsonBody)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._authHeaders, ...?headers};
      final jsonBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .patch(uri, headers: mergedHeaders, body: jsonBody)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final mergedHeaders = {..._authHeaders, ...?headers};

      final response = await _client
          .delete(uri, headers: mergedHeaders)
          .timeout(timeout ?? _defaultTimeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Upload de fichier
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    File file, {
    String fieldName = 'file',
    Map<String, String>? fields,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(Map<String, dynamic>)? fromJson,
    void Function(double)? onProgress,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({..._authHeaders, ...?headers});

      // Fichier
      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        file.path,
      );
      request.files.add(multipartFile);

      // Champs additionnels
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Envoyer la requête
      final streamedResponse = await request.send().timeout(
        timeout ?? _defaultTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Construction de l'URI
  Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    String baseUrl = ApiConstants.baseUrl;

    // Ajouter le préfixe API si nécessaire
    if (!endpoint.startsWith('/')) {
      endpoint = '/${ApiConstants.apiPrefix}/$endpoint';
    }

    final uri = Uri.parse('$baseUrl$endpoint');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }

    return uri;
  }

  // Traitement de la réponse
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final statusCode = response.statusCode;

    // Décoder le body JSON
    Map<String, dynamic> jsonData = {};
    try {
      if (response.body.isNotEmpty) {
        jsonData = jsonDecode(response.body);
      }
    } catch (e) {
      throw ApiException(
        message: 'Réponse JSON invalide',
        type: ApiErrorType.unknown,
        statusCode: statusCode,
      );
    }

    // Vérifier le status code
    if (statusCode >= 200 && statusCode < 300) {
      // Succès
      if (fromJson != null && jsonData['data'] != null) {
        final data = fromJson(jsonData['data']);
        return ApiResponse.success(data, message: jsonData['message']);
      } else {
        return ApiResponse.success(jsonData as T, message: jsonData['message']);
      }
    } else {
      // Erreur
      throw _createApiException(statusCode, jsonData);
    }
  }

  // Gestion des erreurs
  ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    if (error is SocketException) {
      return const ApiException(
        message: 'Pas de connexion internet',
        type: ApiErrorType.network,
      );
    }

    if (error is TimeoutException ||
        error.toString().contains('TimeoutException')) {
      return const ApiException(
        message: 'Timeout de la requête',
        type: ApiErrorType.timeout,
      );
    }

    return ApiException(
      message: 'Erreur inconnue: ${error.toString()}',
      type: ApiErrorType.unknown,
    );
  }

  // Créer une exception API à partir du status code
  ApiException _createApiException(
    int statusCode,
    Map<String, dynamic> jsonData,
  ) {
    final message = jsonData['message'] ?? 'Erreur serveur';

    ApiErrorType type;
    switch (statusCode) {
      case 400:
        type = ApiErrorType.validation;
        break;
      case 401:
        type = ApiErrorType.unauthorized;
        break;
      case 403:
        type = ApiErrorType.forbidden;
        break;
      case 404:
        type = ApiErrorType.notFound;
        break;
      case 429:
        type = ApiErrorType.rateLimit;
        break;
      case >= 500:
        type = ApiErrorType.serverError;
        break;
      default:
        type = ApiErrorType.unknown;
    }

    return ApiException(
      message: message,
      type: type,
      statusCode: statusCode,
      details: jsonData,
    );
  }

  // Retry avec backoff exponentiel
  Future<ApiResponse<T>> retryRequest<T>(
    Future<ApiResponse<T>> Function() request, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries ||
            e is ApiException && e.type != ApiErrorType.network) {
          rethrow;
        }

        await Future.delayed(delay);
        delay *= 2; // Backoff exponentiel
      }
    }

    throw const ApiException(
      message: 'Échec après plusieurs tentatives',
      type: ApiErrorType.network,
    );
  }

  // Batch requests
  Future<List<ApiResponse<T>>> batchRequests<T>(
    List<Future<ApiResponse<T>>> requests, {
    bool failFast = false,
  }) async {
    if (failFast) {
      return Future.wait(requests);
    } else {
      return Future.wait(
        requests.map(
          (request) => request.catchError((error) {
            return ApiResponse<T>.error(error.toString());
          }),
        ),
      );
    }
  }

  // Nettoyer les ressources
  void dispose() {
    _client.close();
  }
}
