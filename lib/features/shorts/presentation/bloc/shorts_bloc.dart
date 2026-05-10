import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_shorts_access_usecase.dart';
import 'shorts_event.dart';
import 'shorts_state.dart';

class ShortsBloc extends Bloc<ShortsEvent, ShortsState> {
  final CheckShortsAccessUseCase checkShortsAccessUseCase;

  ShortsBloc({
    required this.checkShortsAccessUseCase,
  }) : super(const ShortsLoading()) {
    on<LoadShortsAccessEvent>(_onLoadShortsAccess);
  }

  Future<void> _onLoadShortsAccess(
    LoadShortsAccessEvent event,
    Emitter<ShortsState> emit,
  ) async {
    emit(const ShortsLoading());
    await _emitAccessState(emit: emit, isSubscribed: event.isSubscribed);
  }

  Future<void> _emitAccessState({
    required Emitter<ShortsState> emit,
    required bool isSubscribed,
  }) async {
    final canWatch = await checkShortsAccessUseCase(isSubscribed: isSubscribed);

    if (canWatch) {
      emit(const ShortsLoaded());
    } else {
      emit(const ShortsLocked());
    }
  }
}
