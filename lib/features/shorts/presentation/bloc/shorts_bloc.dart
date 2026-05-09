import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../../domain/usecases/check_shorts_access_usecase.dart';
import 'shorts_event.dart';
import 'shorts_state.dart';

class ShortsBloc extends Bloc<ShortsEvent, ShortsState> {
  final ShortsRepository repository;
  final CheckShortsAccessUseCase checkShortsAccessUseCase;

  ShortsBloc({
    required this.repository,
    required this.checkShortsAccessUseCase,
  }) : super(const ShortsLoading()) {
    on<LoadShortsAccessEvent>(_onLoadShortsAccess);
    on<MarkShortViewedEvent>(_onMarkShortViewed);
  }

  Future<void> _onLoadShortsAccess(
    LoadShortsAccessEvent event,
    Emitter<ShortsState> emit,
  ) async {
    emit(const ShortsLoading());
    await _emitAccessState(emit: emit, isSubscribed: event.isSubscribed);
  }

  Future<void> _onMarkShortViewed(
    MarkShortViewedEvent event,
    Emitter<ShortsState> emit,
  ) async {
    final canWatch =
        await checkShortsAccessUseCase(isSubscribed: event.isSubscribed);
    if (!canWatch) {
      // Already at limit — show lock for the next video attempt.
      await _emitAccessState(emit: emit, isSubscribed: event.isSubscribed);
      return;
    }

    await repository.markReelViewed(event.reelId);
    // Emit loaded with the updated count. Do NOT re-check access here so the
    // user can finish watching the video that pushed them to the threshold.
    // The lock will surface on the next MarkShortViewedEvent when canWatch
    // returns false.
    final viewedCount = await repository.getViewedShortsCount();
    emit(ShortsLoaded(
      viewedCount: viewedCount,
      freeThreshold: AppConfig.freeShortsThreshold,
      isLimitEnabled: AppConfig.enableShortsLimit,
    ));
  }

  Future<void> _emitAccessState({
    required Emitter<ShortsState> emit,
    required bool isSubscribed,
  }) async {
    final viewedCount = await repository.getViewedShortsCount();
    final canWatch = await checkShortsAccessUseCase(isSubscribed: isSubscribed);

    if (canWatch) {
      emit(ShortsLoaded(
        viewedCount: viewedCount,
        freeThreshold: AppConfig.freeShortsThreshold,
        isLimitEnabled: AppConfig.enableShortsLimit,
      ));
    } else {
      emit(ShortsLocked(
        viewedCount: viewedCount,
        freeThreshold: AppConfig.freeShortsThreshold,
        isLimitEnabled: AppConfig.enableShortsLimit,
      ));
    }
  }
}
