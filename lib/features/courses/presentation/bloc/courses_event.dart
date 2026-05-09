import 'package:equatable/equatable.dart';

abstract class CoursesEvent extends Equatable {
  const CoursesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCoursesEvent extends CoursesEvent {
  final int? page;
  final int? perPage;
  final int? categoryId;
  final int? specialtyId;
  final bool refresh;

  const LoadCoursesEvent({
    this.page,
    this.perPage,
    this.categoryId,
    this.specialtyId,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, perPage, categoryId, specialtyId, refresh];
}

class LoadMoreCoursesEvent extends CoursesEvent {
  const LoadMoreCoursesEvent();
}

class LoadCourseByIdEvent extends CoursesEvent {
  final int id;

  const LoadCourseByIdEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class LoadMyCoursesEvent extends CoursesEvent {
  final bool refresh;
  final int page;

  const LoadMyCoursesEvent({this.refresh = false, this.page = 1});

  @override
  List<Object?> get props => [refresh, page];
}

class LoadMoreMyCoursesEvent extends CoursesEvent {
  const LoadMoreMyCoursesEvent();
}

class FilterByCategoryEvent extends CoursesEvent {
  final int? categoryId;

  const FilterByCategoryEvent({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class FilterBySpecialtyEvent extends CoursesEvent {
  final int? specialtyId;

  const FilterBySpecialtyEvent({this.specialtyId});

  @override
  List<Object?> get props => [specialtyId];
}

class ClearFiltersEvent extends CoursesEvent {
  const ClearFiltersEvent();
}

class ClearCoursesStateEvent extends CoursesEvent {
  const ClearCoursesStateEvent();
}



