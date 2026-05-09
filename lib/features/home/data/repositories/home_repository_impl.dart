import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, HomeData>> getHomeData() async {
    try {
      final homeData = await remoteDataSource.getHomeData();
      return Right(homeData);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedList<Course>>> getLatestCourses({
    required PaginationParams pagination,
  }) async {
    try {
      final result = await remoteDataSource.getLatestCourses(pagination: pagination);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedList<Course>>> getFreeCourses({
    required PaginationParams pagination,
  }) async {
    try {
      final result = await remoteDataSource.getFreeCourses(pagination: pagination);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedList<Course>>> getPopularCourses({
    required PaginationParams pagination,
  }) async {
    try {
      final result = await remoteDataSource.getPopularCourses(pagination: pagination);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }
}



