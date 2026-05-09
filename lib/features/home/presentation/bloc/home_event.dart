import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

class RefreshHomeDataEvent extends HomeEvent {}

class StartRealtimeUpdatesEvent extends HomeEvent {}

class StopRealtimeUpdatesEvent extends HomeEvent {}

class RealtimeHomeDataUpdateEvent extends HomeEvent {
  final dynamic homeData;
  const RealtimeHomeDataUpdateEvent(this.homeData);

  @override
  List<Object?> get props => [homeData];
}

class LoadLatestCoursesEvent extends HomeEvent {
  final int page;
  const LoadLatestCoursesEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class LoadMoreLatestCoursesEvent extends HomeEvent {}

class LoadFreeCoursesEvent extends HomeEvent {
  final int page;
  const LoadFreeCoursesEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class LoadMoreFreeCoursesEvent extends HomeEvent {}

class LoadPopularCoursesEvent extends HomeEvent {
  final int page;
  const LoadPopularCoursesEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class LoadMorePopularCoursesEvent extends HomeEvent {}



