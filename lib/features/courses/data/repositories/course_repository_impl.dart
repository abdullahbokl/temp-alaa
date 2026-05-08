import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../home/domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;

  CourseRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaginatedList<Course>>> getCourses({
    required PaginationParams pagination,
    int? categoryId,
    int? specialtyId,
  }) async {
    try {
      final courses = await remoteDataSource.getCourses(
        pagination: pagination,
        categoryId: categoryId,
        specialtyId: specialtyId,
      );
      return Right(courses);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, Course>> getCourseById({required int id}) async {
    try {
      final course = await remoteDataSource.getCourseById(id);
      return Right(course);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Course>>> getMyCourses() async {
    try {
      final courses = await remoteDataSource.getMyCourses();
      return Right(courses);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }
}



