import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/realtime_update_service.dart';
import '../../domain/usecases/get_home_data_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeDataUseCase getHomeDataUseCase;
  final RealtimeUpdateService _realtimeUpdateService = sl<RealtimeUpdateService>();
  bool _isLoading = false;

  HomeBloc({
    required this.getHomeDataUseCase,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
    on<StartRealtimeUpdatesEvent>(_onStartRealtimeUpdates);
    on<StopRealtimeUpdatesEvent>(_onStopRealtimeUpdates);
    on<RealtimeHomeDataUpdateEvent>(_onRealtimeHomeDataUpdate);

    add(StartRealtimeUpdatesEvent());
  }
  
  Future<void> _onStartRealtimeUpdates(
    StartRealtimeUpdatesEvent event,
    Emitter<HomeState> emit,
  ) async {
    _realtimeUpdateService.startPolling(
      key: 'home_data',
      updateCallback: () async {
        final result = await getHomeDataUseCase();
        result.fold(
          (_) {},
          (homeData) => add(RealtimeHomeDataUpdateEvent(homeData)),
        );
      },
    );
  }

  Future<void> _onRealtimeHomeDataUpdate(
    RealtimeHomeDataUpdateEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoaded(event.homeData));
  }
  
  Future<void> _onStopRealtimeUpdates(
    StopRealtimeUpdatesEvent event,
    Emitter<HomeState> emit,
  ) async {
    _realtimeUpdateService.stopPolling('home_data');
  }
  
  @override
  Future<void> close() {
    _realtimeUpdateService.stopPolling('home_data');
    return super.close();
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (_isLoading) return;

    final currentState = state;
    if (currentState is HomeLoaded) {
      _isLoading = true;
      emit(HomeLoading(cachedData: currentState.homeData));
    } else {
      _isLoading = true;
      emit(HomeLoading());
    }

    final result = await getHomeDataUseCase();

    _isLoading = false;
    result.fold(
      (failure) {
        if (currentState is HomeLoaded) {
          emit(HomeError(failure.message, cachedData: currentState.homeData));
        } else {
          emit(HomeError(failure.message));
        }
      },
      (homeData) => emit(HomeLoaded(homeData)),
    );
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    final cachedData = currentState is HomeLoaded ? currentState.homeData : null;
    
    final result = await getHomeDataUseCase();

    result.fold(
      (failure) {
        if (cachedData != null) {
          emit(HomeError(failure.message, cachedData: cachedData));
        } else {
          emit(HomeError(failure.message));
        }
      },
      (homeData) => emit(HomeLoaded(homeData)),
    );
  }
}



