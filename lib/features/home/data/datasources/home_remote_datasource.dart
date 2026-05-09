import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/request_auth.dart';
import '../../../../core/network/cache_service.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../../../core/pagination/pagination_parser.dart';
import '../../domain/entities/course.dart';
import '../models/course_model.dart';
import '../models/home_data_model.dart';

HomeDataModel parseHomeDataInIsolate(Map<String, dynamic> json) {
  return HomeDataModel.fromJson(json);
}

List<CourseModel> parseCourseListInIsolate(List<dynamic> rawItems) {
  return rawItems
      .map((c) => CourseModel.fromJson(c as Map<String, dynamic>))
      .toList();
}

abstract class HomeRemoteDataSource {
  Future<HomeDataModel> getHomeData();
  Future<PaginatedList<Course>> getLatestCourses({required PaginationParams pagination});
  Future<PaginatedList<Course>> getFreeCourses({required PaginationParams pagination});
  Future<PaginatedList<Course>> getPopularCourses({required PaginationParams pagination});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient dioClient;

  HomeRemoteDataSourceImpl(this.dioClient);

  @override
  Future<HomeDataModel> getHomeData() async {
    try {
      final response = await dioClient.get(
        ApiConstants.homeApi,
        auth: AuthRequirement.public,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData == null) return const HomeDataModel();

        final Map<String, dynamic> raw;
        if (responseData['data'] != null) {
          raw = responseData['data'] as Map<String, dynamic>;
        } else if (responseData['banners'] != null || responseData['latest_courses'] != null) {
          raw = responseData;
        } else {
          return const HomeDataModel();
        }
        return compute(parseHomeDataInIsolate, raw);
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب البيانات',
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
    }
  }

  @override
  Future<PaginatedList<Course>> getLatestCourses({
    required PaginationParams pagination,
  }) async {
    return _getPaginatedCourses(
      ApiConstants.courses,
      pagination,
      extraParams: {'sort': 'latest'},
    );
  }

  @override
  Future<PaginatedList<Course>> getFreeCourses({
    required PaginationParams pagination,
  }) async {
    return _getPaginatedCourses(
      ApiConstants.courses,
      pagination,
      extraParams: {'is_free': 1},
    );
  }

  @override
  Future<PaginatedList<Course>> getPopularCourses({
    required PaginationParams pagination,
  }) async {
    return _getPaginatedCourses(
      ApiConstants.courses,
      pagination,
      extraParams: {'sort': 'popular'},
    );
  }

  Future<PaginatedList<Course>> _getPaginatedCourses(
    String endpoint,
    PaginationParams pagination, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    try {
      final queryParams = {
        ...pagination.toPerPageMap(),
        ...extraParams,
      };

      final response = await dioClient.get(
        endpoint,
        queryParameters: queryParams,
        auth: AuthRequirement.optional,
      );

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        final rawItems = data['data'] is List
            ? data['data'] as List
            : data['courses'] is List
                ? data['courses'] as List
                : [];

        final courseModels = await compute(parseCourseListInIsolate, rawItems);

        final paginated = PaginationParser.parse<Course>(
          responseData: data,
          requestedPage: pagination.page,
          requestedLimit: pagination.limit,
          mapItems: (_) => courseModels,
        );

        return PaginatedList<Course>(
          items: paginated.items,
          page: paginated.page,
          limit: paginated.limit,
          hasMore: paginated.hasMore,
          total: paginated.total,
        );
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب الكورسات',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'خطأ في الاتصال بالخادم',
        statusCode: e.response?.statusCode,
      );
    }
  }
}


