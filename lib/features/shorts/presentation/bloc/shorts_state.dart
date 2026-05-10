import 'package:equatable/equatable.dart';

abstract class ShortsState extends Equatable {
  const ShortsState();

  @override
  List<Object?> get props => [];
}

class ShortsLoading extends ShortsState {
  const ShortsLoading();
}

class ShortsLoaded extends ShortsState {
  const ShortsLoaded();
}

class ShortsLocked extends ShortsState {
  const ShortsLocked();
}
