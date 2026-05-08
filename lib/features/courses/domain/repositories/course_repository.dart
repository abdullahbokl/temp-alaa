import 'package:dartz/dartz.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/course.dart';

abstract class CourseRepository {
  Future<Either<Failure, PaginatedList<Course>>> getCourses({
    required PaginationParams pagination,
    int? categoryId,
    int? specialtyId,
  });

  Future<Either<Failure, Course>> getCourseById({required int id});

  Future<Either<Failure, List<Course>>> getMyCourses();
}



