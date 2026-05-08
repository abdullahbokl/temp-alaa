import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/course.dart';

class CoursesState extends Equatable {
  final List<Course> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;
  final int? categoryId;
  final int? specialtyId;
  final bool isMyCoursesMode;

  const CoursesState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.errorMessage,
    this.categoryId,
    this.specialtyId,
    this.isMyCoursesMode = false,
  });

  CoursesState copyWith({
    List<Course>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    int? categoryId,
    int? specialtyId,
    bool? isMyCoursesMode,
    bool clearError = false,
  }) {
    return CoursesState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      categoryId: categoryId ?? this.categoryId,
      specialtyId: specialtyId ?? this.specialtyId,
      isMyCoursesMode: isMyCoursesMode ?? this.isMyCoursesMode,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isEmpty => !isInitialLoading && items.isEmpty && !hasError;

  @override
  List<Object?> get props => [
        items,
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        hasMore,
        currentPage,
        errorMessage,
        categoryId,
        specialtyId,
        isMyCoursesMode,
      ];
}
