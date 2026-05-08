import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/request_auth.dart';
import '../../../../core/network/cache_service.dart';
import '../models/home_data_model.dart';

HomeDataModel parseHomeDataInIsolate(Map<String, dynamic> json) {
  return HomeDataModel.fromJson(json);
}

abstract class HomeRemoteDataSource {
  Future<HomeDataModel> getHomeData();
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
}


