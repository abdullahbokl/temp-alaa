import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'cache_service.dart';
import 'request_auth.dart';
import 'token_refresh_interceptor.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;
  final Map<String, CancelToken> _cancelTokens = {};

  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        persistentConnection: true,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_secureStorage));
    _dio.interceptors.add(TokenRefreshInterceptor(
      secureStorage: _secureStorage,
      mainDio: _dio,
    ));
    _dio.interceptors.add(_CacheUserInterceptor());

    final cacheOptions = CacheService.cacheOptions;
    if (cacheOptions != null) {
      _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
    }

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  Dio get dio => _dio;

  void cancelRequest(String tag) {
    _cancelTokens[tag]?.cancel('Request cancelled');
    _cancelTokens.remove(tag);
  }

  void cancelAllRequests() {
    for (final token in _cancelTokens.values) {
      token.cancel('All requests cancelled');
    }
    _cancelTokens.clear();
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? cancelTag,
    AuthRequirement? auth,
  }) async {
    CancelToken? cancelToken;
    if (cancelTag != null) {
      cancelRequest(cancelTag);
      cancelToken = CancelToken();
      _cancelTokens[cancelTag] = cancelToken;
    }

    final mergedOptions = _withAuthOptions(path, options, auth);

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      return response;
    } catch (e) {
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? cancelTag,
    AuthRequirement? auth,
  }) async {
    CancelToken? cancelToken;
    if (cancelTag != null) {
      cancelRequest(cancelTag);
      cancelToken = CancelToken();
      _cancelTokens[cancelTag] = cancelToken;
    }

    final mergedOptions = _withAuthOptions(path, options, auth);

    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      return response;
    } catch (e) {
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? cancelTag,
    AuthRequirement? auth,
  }) async {
    CancelToken? cancelToken;
    if (cancelTag != null) {
      cancelRequest(cancelTag);
      cancelToken = CancelToken();
      _cancelTokens[cancelTag] = cancelToken;
    }

    final mergedOptions = _withAuthOptions(path, options, auth);

    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      return response;
    } catch (e) {
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? cancelTag,
    AuthRequirement? auth,
  }) async {
    CancelToken? cancelToken;
    if (cancelTag != null) {
      cancelRequest(cancelTag);
      cancelToken = CancelToken();
      _cancelTokens[cancelTag] = cancelToken;
    }

    final mergedOptions = _withAuthOptions(path, options, auth);

    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      return response;
    } catch (e) {
      if (cancelTag != null) _cancelTokens.remove(cancelTag);
      rethrow;
    }
  }

  Options _withAuthOptions(
      String path, Options? options, AuthRequirement? auth) {
    final requirement = auth ?? RequestAuthPolicyResolver.resolve(path);
    final merged = options ?? Options();
    merged.extra ??= <String, dynamic>{};
    merged.extra![RequestAuthMeta.authRequirementKey] = requirement.name;
    return merged;
  }
}

class _CacheUserInterceptor extends QueuedInterceptor {
  static const String _headerKey = 'X-Cache-User';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final hasAuth = options.extra[RequestAuthMeta.authAttachedKey] == true;
    options.headers[_headerKey] = hasAuth ? 'auth' : 'guest';
    handler.next(options);
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  _AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authRequirement = _readAuthRequirement(options);

    final token = await _secureStorage.getAccessToken();
    final hasToken = token != null && token.isNotEmpty;

    switch (authRequirement) {
      case AuthRequirement.public:
      case AuthRequirement.guest:
        options.extra[RequestAuthMeta.authAttachedKey] = false;
        handler.next(options);
        return;

      case AuthRequirement.optional:
        if (hasToken) {
          options.headers['Authorization'] = 'Bearer $token';
          options.extra[RequestAuthMeta.authAttachedKey] = true;
        } else {
          options.extra[RequestAuthMeta.authAttachedKey] = false;
        }
        handler.next(options);
        return;

      case AuthRequirement.protected:
        if (hasToken) {
          options.headers['Authorization'] = 'Bearer $token';
          options.extra[RequestAuthMeta.authAttachedKey] = true;
          handler.next(options);
        } else {
          options.extra[RequestAuthMeta.authAttachedKey] = false;
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Authentication required',
              type: DioExceptionType.unknown,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                statusMessage: 'Unauthorized',
              ),
            ),
          );
        }
        return;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }

  AuthRequirement _readAuthRequirement(RequestOptions options) {
    final raw = options.extra[RequestAuthMeta.authRequirementKey];
    if (raw is String) {
      return AuthRequirement.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => AuthRequirement.optional,
      );
    }
    return AuthRequirement.optional;
  }
}
