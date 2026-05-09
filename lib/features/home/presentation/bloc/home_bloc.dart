import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/pagination/paginated_list.dart';
import '../../../../core/services/realtime_update_service.dart';
import '../../domain/entities/course.dart';
import '../../domain/usecases/get_free_courses_usecase.dart';
import '../../domain/usecases/get_home_data_usecase.dart';
import '../../domain/usecases/get_latest_courses_usecase.dart';
import '../../domain/usecases/get_popular_courses_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeDataUseCase getHomeDataUseCase;
  final GetLatestCoursesUseCase getLatestCoursesUseCase;
  final GetFreeCoursesUseCase getFreeCoursesUseCase;
  final GetPopularCoursesUseCase getPopularCoursesUseCase;
  final RealtimeUpdateService _realtimeUpdateService = sl<RealtimeUpdateService>();
  bool _isLoading = false;

  HomeBloc({
    required this.getHomeDataUseCase,
    required this.getLatestCoursesUseCase,
    required this.getFreeCoursesUseCase,
    required this.getPopularCoursesUseCase,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
    on<StartRealtimeUpdatesEvent>(_onStartRealtimeUpdates);
    on<StopRealtimeUpdatesEvent>(_onStopRealtimeUpdates);
    on<RealtimeHomeDataUpdateEvent>(_onRealtimeHomeDataUpdate);
    on<LoadLatestCoursesEvent>(_onLoadLatestCourses);
    on<LoadMoreLatestCoursesEvent>(_onLoadMoreLatestCourses);
    on<LoadFreeCoursesEvent>(_onLoadFreeCourses);
    on<LoadMoreFreeCoursesEvent>(_onLoadMoreFreeCourses);
    on<LoadPopularCoursesEvent>(_onLoadPopularCourses);
    on<LoadMorePopularCoursesEvent>(_onLoadMorePopularCourses);
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
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(currentState.copyWith(homeData: event.homeData));
    } else {
      emit(HomeLoaded(event.homeData));
    }
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
      (homeData) {
        emit(HomeLoaded(homeData));
        add(const LoadLatestCoursesEvent());
        add(const LoadFreeCoursesEvent());
        add(const LoadPopularCoursesEvent());
      },
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
      (homeData) {
        emit(HomeLoaded(homeData));
        add(const LoadLatestCoursesEvent());
        add(const LoadFreeCoursesEvent());
        add(const LoadPopularCoursesEvent());
      },
    );
  }

  Future<void> _onLoadLatestCourses(
    LoadLatestCoursesEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final result = await getLatestCoursesUseCase(
      pagination: PaginationParams(page: event.page),
    );

    result.fold(
      (failure) {},
      (paginatedList) {
        emit(currentState.copyWith(
          latestCourses: event.page == 1
              ? paginatedList
              : PaginatedList<Course>(
                  items: [...currentState.latestCourses.items, ...paginatedList.items],
                  page: paginatedList.page,
                  limit: paginatedList.limit,
                  hasMore: paginatedList.hasMore,
                  total: paginatedList.total,
                ),
        ));
      },
    );
  }

  Future<void> _onLoadMoreLatestCourses(
    LoadMoreLatestCoursesEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    if (currentState.isLoadingMoreLatest || !currentState.latestCourses.hasMore) return;

    emit(currentState.copyWith(isLoadingMoreLatest: true));
    add(LoadLatestCoursesEvent(page: currentState.latestCourses.page + 1));
    emit((state as HomeLoaded).copyWith(isLoadingMoreLatest: false));
  }

  Future<void> _onLoadFreeCourses(
    LoadFreeCoursesEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final result = await getFreeCoursesUseCase(
      pagination: PaginationParams(page: event.page),
    );

    result.fold(
      (failure) {},
      (paginatedList) {
        emit(currentState.copyWith(
          freeCourses: event.page == 1
              ? paginatedList
              : PaginatedList<Course>(
                  items: [...currentState.freeCourses.items, ...paginatedList.items],
                  page: paginatedList.page,
                  limit: paginatedList.limit,
                  hasMore: paginatedList.hasMore,
                  total: paginatedList.total,
                ),
        ));
      },
    );
  }

  Future<void> _onLoadMoreFreeCourses(
    LoadMoreFreeCoursesEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    if (currentState.isLoadingMoreFree || !currentState.freeCourses.hasMore) return;

    emit(currentState.copyWith(isLoadingMoreFree: true));
    add(LoadFreeCoursesEvent(page: currentState.freeCourses.page + 1));
    emit((state as HomeLoaded).copyWith(isLoadingMoreFree: false));
  }

  Future<void> _onLoadPopularCourses(
    LoadPopularCoursesEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final result = await getPopularCoursesUseCase(
      pagination: PaginationParams(page: event.page),
    );

    result.fold(
      (failure) {},
      (paginatedList) {
        emit(currentState.copyWith(
          popularCourses: event.page == 1
              ? paginatedList
              : PaginatedList<Course>(
                  items: [...currentState.popularCourses.items, ...paginatedList.items],
                  page: paginatedList.page,
                  limit: paginatedList.limit,
                  hasMore: paginatedList.hasMore,
                  total: paginatedList.total,
                ),
        ));
      },
    );
  }

  Future<void> _onLoadMorePopularCourses(
    LoadMorePopularCoursesEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    if (currentState.isLoadingMorePopular || !currentState.popularCourses.hasMore) return;

    emit(currentState.copyWith(isLoadingMorePopular: true));
    add(LoadPopularCoursesEvent(page: currentState.popularCourses.page + 1));
    emit((state as HomeLoaded).copyWith(isLoadingMorePopular: false));
  }
}


