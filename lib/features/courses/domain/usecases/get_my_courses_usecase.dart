import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../home/domain/entities/course.dart';
import '../repositories/course_repository.dart';

class GetMyCoursesUseCase {
  final CourseRepository repository;

  GetMyCoursesUseCase(this.repository);

  Future<Either<Failure, PaginatedList<Course>>> call({
    required PaginationParams pagination,
  }) async {
    return await repository.getMyCourses(pagination: pagination);
  }
}




