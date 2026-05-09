import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class _RetryRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _RetryRequest(this.requestOptions, this.handler);
}

class TokenRefreshInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _refreshDio;
  final Dio _mainDio;
  bool _isRefreshing = false;
  final List<_RetryRequest> _requestQueue = [];

  TokenRefreshInterceptor({
    required SecureStorageService secureStorage,
    required Dio mainDio,
  })  : _secureStorage = secureStorage,
        _mainDio = mainDio,
        _refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !_isRefreshRequest(err.requestOptions.path)) {
      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        handler.next(err);
        return;
      }

      if (_isRefreshing) {
        _requestQueue.add(_RetryRequest(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;
      try {
        final newToken = await _performRefresh(refreshToken);
        final retryOptions = err.requestOptions.copyWith(
          headers: {'Authorization': 'Bearer $newToken'},
        );
        final response = await _mainDio.fetch(retryOptions);
        handler.resolve(response);
        _retryQueuedRequests(newToken);
      } catch (e) {
        await _secureStorage.clearAll();
        _rejectQueuedRequests();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<String> _performRefresh(String refreshToken) async {
    final response = await _refreshDio.post(
      ApiConstants.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    final newAccessToken = response.data['access_token'] as String;
    final newRefreshToken = response.data['refresh_token'] as String?;
    await _secureStorage.saveAccessToken(newAccessToken);
    if (newRefreshToken != null) {
      await _secureStorage.saveRefreshToken(newRefreshToken);
    }
    return newAccessToken;
  }

  void _retryQueuedRequests(String newToken) {
    for (final retry in _requestQueue) {
      final retryOptions = retry.requestOptions.copyWith(
        headers: {'Authorization': 'Bearer $newToken'},
      );
      _mainDio.fetch(retryOptions).then((response) {
        retry.handler.resolve(response);
      }).catchError((error) {
        retry.handler.next(error as DioException);
      });
    }
    _requestQueue.clear();
  }

  void _rejectQueuedRequests() {
    for (final retry in _requestQueue) {
      retry.handler.next(
        DioException(
          requestOptions: retry.requestOptions,
          error: 'Session expired',
          type: DioExceptionType.unknown,
        ),
      );
    }
    _requestQueue.clear();
  }

  bool _isRefreshRequest(String path) {
    return path.endsWith(ApiConstants.refreshToken);
  }
}
