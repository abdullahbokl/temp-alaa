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



