import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../entities/course.dart';
import '../entities/home_data.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeData>> getHomeData();
  Future<Either<Failure, PaginatedList<Course>>> getLatestCourses({required PaginationParams pagination});
  Future<Either<Failure, PaginatedList<Course>>> getFreeCourses({required PaginationParams pagination});
  Future<Either<Failure, PaginatedList<Course>>> getPopularCourses({required PaginationParams pagination});
}



