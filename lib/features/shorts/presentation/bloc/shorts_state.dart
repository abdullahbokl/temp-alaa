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
  final int viewedCount;
  final int freeThreshold;
  final bool isLimitEnabled;

  const ShortsLoaded({
    required this.viewedCount,
    required this.freeThreshold,
    required this.isLimitEnabled,
  });

  @override
  List<Object?> get props => [viewedCount, freeThreshold, isLimitEnabled];
}

class ShortsLocked extends ShortsState {
  final int viewedCount;
  final int freeThreshold;
  final bool isLimitEnabled;

  const ShortsLocked({
    required this.viewedCount,
    required this.freeThreshold,
    required this.isLimitEnabled,
  });

  @override
  List<Object?> get props => [viewedCount, freeThreshold, isLimitEnabled];
}
