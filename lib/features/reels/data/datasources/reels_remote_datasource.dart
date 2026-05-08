import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/reel_category_model.dart';
import '../models/reels_feed_meta_model.dart';
import '../models/reels_feed_response_model.dart';

ReelsFeedResponseModel parseReelsFeedInIsolate(Map<String, dynamic> json) {
  return ReelsFeedResponseModel.fromJson(json);
}

List<ReelCategoryModel> parseReelCategoriesInIsolate(List<dynamic> jsonList) {
  return jsonList
      .map((json) => ReelCategoryModel.fromJson(json as Map<String, dynamic>))
      .toList();
}

abstract class ReelsRemoteDataSource {
  Future<ReelsFeedResponseModel> getReelsFeed({
    int perPage = 10,
    String? cursor,
    String? nextPageUrl,
    int? categoryId,
  });

  Future<void> recordReelView(int reelId);

  Future<void> likeReel(int reelId);

  Future<void> unlikeReel(int reelId);

  Future<List<ReelCategoryModel>> getReelCategoriesWithReels();

  Future<ReelsFeedResponseModel> getUserReels({
    required int userId,
    int perPage = 10,
    int page = 1,
  });

  Future<ReelsFeedResponseModel> getUserLikedReels({
    required int userId,
    int perPage = 10,
    int page = 1,
  });
}

class ReelsRemoteDataSourceImpl implements ReelsRemoteDataSource {
  final DioClient dioClient;

  ReelsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<ReelsFeedResponseModel> getReelsFeed({
    int perPage = 10,
    String? cursor,
    String? nextPageUrl,
    int? categoryId,
  }) async {
    try {
      String endpoint = ApiConstants.reelsFeed;
      Map<String, dynamic>? queryParams;

      if (nextPageUrl != null && nextPageUrl.isNotEmpty) {
        final uri = Uri.parse(nextPageUrl);

        if (nextPageUrl.startsWith('http')) {
          final pathParts = uri.path.split('/api/');
          if (pathParts.length > 1) {
            endpoint = pathParts[1];
          } else {
            endpoint = uri.path.replaceFirst('/', '');
          }
        } else {
          endpoint = nextPageUrl.replaceFirst('/api/', '').replaceFirst('api/', '');
        }

        queryParams = uri.queryParameters.isNotEmpty ? uri.queryParameters : null;
      } else {
        queryParams = <String, dynamic>{
          'per_page': perPage,
        };

        if (categoryId != null) {
          queryParams['categories'] = categoryId;
        }

        if (cursor != null && cursor.isNotEmpty) {
          queryParams['cursor'] = cursor;
        }
      }

      final response = await dioClient.get(
        endpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData == null) {
          return const ReelsFeedResponseModel(
            reels: [],
            meta: ReelsFeedMetaModel(perPage: 10, hasMore: false),
          );
        }

        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final data = responseData['data'];
          final map = data is Map<String, dynamic> ? data : responseData;
          return compute(parseReelsFeedInIsolate, map);
        }

        if (responseData['data'] != null || responseData['items'] != null) {
          return compute(parseReelsFeedInIsolate, responseData);
        }

        return const ReelsFeedResponseModel(
          reels: [],
          meta: ReelsFeedMetaModel(perPage: 10, hasMore: false),
        );
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب الفيديوهات',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const ReelsFeedResponseModel(
          reels: [],
          meta: ReelsFeedMetaModel(perPage: 10, hasMore: false),
        );
      }

      String errorMessage = 'خطأ في الاتصال بالخادم';

      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw ServerException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> recordReelView(int reelId) async {
    try {
      final endpoint = ApiConstants.recordReelView.replaceAll('{id}', reelId.toString());
      AppLogger.network('ReelsDataSource: Recording view - POST $endpoint');
      
      final response = await dioClient.post(endpoint);
      AppLogger.network('ReelsDataSource: View response status: ${response.statusCode}');
      AppLogger.network('ReelsDataSource: View response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.network('ReelsDataSource: View recorded successfully');
        return;
      }

      throw ServerException(
        message: response.data?['message'] ?? 'فشل في تسجيل المشاهدة',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      AppLogger.error('ReelsDataSource: View DioException', error: e.message);
      AppLogger.network('ReelsDataSource: View error response: ${e.response?.data}');
      
      String errorMessage = 'خطأ في الاتصال بالخادم';

      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw ServerException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.error('ReelsDataSource: View unexpected error', error: e);
      throw ServerException(message: 'خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> likeReel(int reelId) async {
    try {
      final endpoint = ApiConstants.likeReel.replaceAll('{id}', reelId.toString());
      AppLogger.network('ReelsDataSource: Liking reel - POST $endpoint');
      
      final response = await dioClient.post(endpoint);
      AppLogger.network('ReelsDataSource: Like response status: ${response.statusCode}');
      AppLogger.network('ReelsDataSource: Like response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.network('ReelsDataSource: Like recorded successfully');
        return;
      }

      throw ServerException(
        message: response.data?['message'] ?? 'فشل في الإعجاب',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      AppLogger.error('ReelsDataSource: Like DioException', error: e.message);
      AppLogger.network('ReelsDataSource: Like error response: ${e.response?.data}');
      
      String errorMessage = 'خطأ في الاتصال بالخادم';

      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw ServerException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.error('ReelsDataSource: Like unexpected error', error: e);
      throw ServerException(message: 'خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> unlikeReel(int reelId) async {
    try {
      final endpoint = ApiConstants.likeReel.replaceAll('{id}', reelId.toString());
      AppLogger.network('ReelsDataSource: Unliking reel - DELETE $endpoint');
      
      final response = await dioClient.delete(endpoint);
      AppLogger.network('ReelsDataSource: Unlike response status: ${response.statusCode}');
      AppLogger.network('ReelsDataSource: Unlike response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        AppLogger.network('ReelsDataSource: Unlike recorded successfully');
        return;
      }

      throw ServerException(
        message: response.data?['message'] ?? 'فشل في إلغاء الإعجاب',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      AppLogger.error('ReelsDataSource: Unlike DioException', error: e.message);
      AppLogger.network('ReelsDataSource: Unlike error response: ${e.response?.data}');
      
      String errorMessage = 'خطأ في الاتصال بالخادم';

      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw ServerException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.error('ReelsDataSource: Unlike unexpected error', error: e);
      throw ServerException(message: 'خطأ غير متوقع: $e');
    }
  }

  @override
  Future<List<ReelCategoryModel>> getReelCategoriesWithReels() async {
    try {
      final response = await dioClient.get(
        ApiConstants.reelCategoriesWithReels,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final data = responseData['data'];

          final categoriesList = data['data'] ?? data;
          
          if (categoriesList is List) {
            return compute(parseReelCategoriesInIsolate, List<dynamic>.from(categoriesList));
          }
        }

        if (responseData['data'] is List) {
          return compute(parseReelCategoriesInIsolate, List<dynamic>.from(responseData['data'] as List));
        }

        return [];
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب فئات الرييلز',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String errorMessage = 'خطأ في الاتصال بالخادم';

      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw ServerException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'خطأ غير متوقع: $e');
    }
  }

  @override
  Future<ReelsFeedResponseModel> getUserReels({
    required int userId,
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final endpoint = ApiConstants.userReels.replaceAll('{userId}', userId.toString());
      
      final response = await dioClient.get(
        endpoint,
        queryParameters: {
          'per_page': perPage,
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['status'] == 'success' && responseData['data'] != null) {
          return compute(
            parseReelsFeedInIsolate,
            responseData['data'] as Map<String, dynamic>,
          );
        }

        if (responseData['data'] != null || responseData['items'] != null) {
          return compute(
            parseReelsFeedInIsolate,
            responseData as Map<String, dynamic>,
          );
        }

        return const ReelsFeedResponseModel(
          reels: [],
          meta: ReelsFeedMetaModel(perPage: 10, hasMore: false),
        );
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب فيديوهات المستخدم',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String errorMessage = 'خطأ في الاتصال بالخادم';

      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw ServerException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'خطأ غير متوقع: $e');
    }
  }

  @override
  Future<ReelsFeedResponseModel> getUserLikedReels({
    required int userId,
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final endpoint = ApiConstants.userLikedReels.replaceAll('{userId}', userId.toString());
      
      final response = await dioClient.get(
        endpoint,
        queryParameters: {
          'per_page': perPage,
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['status'] == 'success' && responseData['data'] != null) {
          return compute(
            parseReelsFeedInIsolate,
            responseData['data'] as Map<String, dynamic>,
          );
        }

        if (responseData['data'] != null || responseData['items'] != null) {
          return compute(
            parseReelsFeedInIsolate,
            responseData as Map<String, dynamic>,
          );
        }

        return const ReelsFeedResponseModel(
          reels: [],
          meta: ReelsFeedMetaModel(perPage: 10, hasMore: false),
        );
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب الفيديوهات المفضلة',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String errorMessage = 'خطأ في الاتصال بالخادم';

      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }

      throw ServerException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'خطأ غير متوقع: $e');
    }
  }
}


