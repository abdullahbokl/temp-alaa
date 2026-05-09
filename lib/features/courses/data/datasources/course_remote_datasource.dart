import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/request_auth.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/pagination/pagination_parser.dart';
import '../../../home/data/models/course_model.dart';

List<CourseModel> parseCoursesListInIsolate(List<dynamic> jsonList) {
  return jsonList.map((json) => CourseModel.fromJson(json)).toList();
}

abstract class CourseRemoteDataSource {
  Future<PaginatedList<CourseModel>> getCourses({
    required PaginationParams pagination,
    int? categoryId,
    int? specialtyId,
  });

  Future<CourseModel> getCourseById(int id);

  Future<PaginatedList<CourseModel>> getMyCourses({
    required PaginationParams pagination,
  });
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final DioClient dioClient;

  CourseRemoteDataSourceImpl(this.dioClient);

  @override
  Future<PaginatedList<CourseModel>> getCourses({
    required PaginationParams pagination,
    int? categoryId,
    int? specialtyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{...pagination.toPerPageMap()};

      final searchParts = <String>[];
      if (categoryId != null) {
        searchParts.add('categories.category_id:$categoryId');
      }
      if (specialtyId != null) {
        searchParts.add('specialty_id:$specialtyId');
      }
      
      if (searchParts.isNotEmpty) {
        queryParams['search'] = searchParts.join(';');
      }

      final response = await dioClient.get(
        ApiConstants.courses,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        cancelTag: 'courses_${categoryId}_${specialtyId}_${pagination.page}',
        auth: AuthRequirement.optional,
      );

      if (response.statusCode == 200) {
        return PaginationParser.parse<CourseModel>(
          responseData: response.data,
          requestedPage: pagination.page,
          requestedLimit: pagination.limit,
          mapItems: (rawItems) {
            if (rawItems.isEmpty) return <CourseModel>[];
            return parseCoursesListInIsolate(rawItems);
          },
        );
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب الكورسات',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل في جلب الكورسات');
    }
  }

  @override
  Future<CourseModel> getCourseById(int id) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.courses}/$id',
        auth: AuthRequirement.optional,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> courseData;

        if (responseData['data'] is Map && responseData['data']['data'] is Map) {
          courseData = responseData['data']['data'];
        } else if (responseData['data'] is Map) {
          courseData = responseData['data'];
        } else if (responseData['course'] is Map) {
          courseData = responseData['course'];
        } else {
          courseData = responseData;
        }

        return CourseModel.fromJson(courseData);
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب الكورس',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل في جلب الكورس');
    }
  }

  @override
  Future<PaginatedList<CourseModel>> getMyCourses({
    required PaginationParams pagination,
  }) async {
    try {
      final response = await dioClient.get(
        ApiConstants.myCourses,
        queryParameters: pagination.toPerPageMap(),
        auth: AuthRequirement.protected,
      );

      if (response.statusCode == 200) {
        return PaginationParser.parse<CourseModel>(
          responseData: response.data,
          requestedPage: pagination.page,
          requestedLimit: pagination.limit,
          mapItems: (rawItems) {
            if (rawItems.isEmpty) return <CourseModel>[];
            return parseCoursesListInIsolate(rawItems);
          },
        );
      }

      throw ServerException(
        message: response.data['message'] ?? 'فشل في جلب كورساتي',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل في جلب كورساتي');
    }
  }

  ServerException _handleDioError(DioException e, String defaultMessage) {
    String errorMessage = defaultMessage;

    if (e.response?.statusCode == 401) {
      errorMessage = 'يجب تسجيل الدخول أولاً';
    } else if (e.response?.statusCode == 403) {
      errorMessage = e.response?.data['message'] ?? 'غير مصرح لك بهذا الإجراء';
    } else if (e.response?.statusCode == 404) {
      errorMessage = e.response?.data['message'] ?? 'الكورس غير موجود';
    } else if (e.response?.data != null && e.response?.data['message'] != null) {
      errorMessage = e.response?.data['message'];
    }

    return ServerException(
      message: errorMessage,
      statusCode: e.response?.statusCode,
    );
  }
}


