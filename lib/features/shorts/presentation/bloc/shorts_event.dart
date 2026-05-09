import 'package:equatable/equatable.dart';

abstract class ShortsEvent extends Equatable {
  const ShortsEvent();

  @override
  List<Object?> get props => [];
}

class LoadShortsAccessEvent extends ShortsEvent {
  final bool isSubscribed;

  const LoadShortsAccessEvent({required this.isSubscribed});

  @override
  List<Object?> get props => [isSubscribed];
}

class MarkShortViewedEvent extends ShortsEvent {
  final int reelId;
  final bool isSubscribed;

  const MarkShortViewedEvent({
    required this.reelId,
    required this.isSubscribed,
  });

  @override
  List<Object?> get props => [reelId, isSubscribed];
}
