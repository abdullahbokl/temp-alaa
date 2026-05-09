import 'package:equatable/equatable.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/home_data.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {
  final HomeData? cachedData;

  const HomeLoading({this.cachedData});

  @override
  List<Object?> get props => [cachedData];
}

class HomeLoaded extends HomeState {
  final HomeData homeData;
  final PaginatedList<Course> latestCourses;
  final PaginatedList<Course> freeCourses;
  final PaginatedList<Course> popularCourses;
  final bool isLoadingMoreLatest;
  final bool isLoadingMoreFree;
  final bool isLoadingMorePopular;

  const HomeLoaded(
    this.homeData, {
    this.latestCourses = const PaginatedList(items: [], page: 1, limit: 10, hasMore: true),
    this.freeCourses = const PaginatedList(items: [], page: 1, limit: 10, hasMore: true),
    this.popularCourses = const PaginatedList(items: [], page: 1, limit: 10, hasMore: true),
    this.isLoadingMoreLatest = false,
    this.isLoadingMoreFree = false,
    this.isLoadingMorePopular = false,
  });

  HomeLoaded copyWith({
    HomeData? homeData,
    PaginatedList<Course>? latestCourses,
    PaginatedList<Course>? freeCourses,
    PaginatedList<Course>? popularCourses,
    bool? isLoadingMoreLatest,
    bool? isLoadingMoreFree,
    bool? isLoadingMorePopular,
  }) {
    return HomeLoaded(
      homeData ?? this.homeData,
      latestCourses: latestCourses ?? this.latestCourses,
      freeCourses: freeCourses ?? this.freeCourses,
      popularCourses: popularCourses ?? this.popularCourses,
      isLoadingMoreLatest: isLoadingMoreLatest ?? this.isLoadingMoreLatest,
      isLoadingMoreFree: isLoadingMoreFree ?? this.isLoadingMoreFree,
      isLoadingMorePopular: isLoadingMorePopular ?? this.isLoadingMorePopular,
    );
  }

  @override
  List<Object?> get props => [
        homeData,
        latestCourses,
        freeCourses,
        popularCourses,
        isLoadingMoreLatest,
        isLoadingMoreFree,
        isLoadingMorePopular,
      ];
}

class HomeError extends HomeState {
  final String message;
  final HomeData? cachedData;

  const HomeError(this.message, {this.cachedData});

  @override
  List<Object?> get props => [message, cachedData];
}



