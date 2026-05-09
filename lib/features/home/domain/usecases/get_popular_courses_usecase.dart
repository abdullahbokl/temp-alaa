import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../entities/course.dart';
import '../repositories/home_repository.dart';

class GetPopularCoursesUseCase {
  final HomeRepository repository;

  GetPopularCoursesUseCase(this.repository);

  Future<Either<Failure, PaginatedList<Course>>> call({
    required PaginationParams pagination,
  }) async {
    return await repository.getPopularCourses(pagination: pagination);
  }
}
