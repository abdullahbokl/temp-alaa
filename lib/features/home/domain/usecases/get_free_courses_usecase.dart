import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../entities/course.dart';
import '../repositories/home_repository.dart';

class GetFreeCoursesUseCase {
  final HomeRepository repository;

  GetFreeCoursesUseCase(this.repository);

  Future<Either<Failure, PaginatedList<Course>>> call({
    required PaginationParams pagination,
  }) async {
    return await repository.getFreeCourses(pagination: pagination);
  }
}
