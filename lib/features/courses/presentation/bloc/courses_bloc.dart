import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/events/global_event_bus.dart';
import '../../../../core/events/subscription_updated_event.dart';
import '../../../../core/pagination/pagination_params.dart';
import '../../../../core/utils/debouncer.dart';
import '../../domain/usecases/get_course_by_id_usecase.dart';
import '../../domain/usecases/get_courses_usecase.dart';
import '../../domain/usecases/get_my_courses_usecase.dart';
import 'courses_event.dart';
import 'courses_state.dart';

class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final GetCoursesUseCase getCoursesUseCase;
  final GetCourseByIdUseCase getCourseByIdUseCase;
  final GetMyCoursesUseCase getMyCoursesUseCase;
  final GlobalEventBus globalEventBus;

  static const int _perPage = 10;
  final Debouncer _filterDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  StreamSubscription<SubscriptionUpdatedEvent>? _subscriptionUpdatedListener;

  CoursesBloc({
    required this.getCoursesUseCase,
    required this.getCourseByIdUseCase,
    required this.getMyCoursesUseCase,
    required this.globalEventBus,
  }) : super(const CoursesState()) {
    on<LoadCoursesEvent>(_onLoadCourses);
    on<LoadMoreCoursesEvent>(_onLoadMoreCourses);
    on<LoadCourseByIdEvent>(_onLoadCourseById);
    on<LoadMyCoursesEvent>(_onLoadMyCourses);
    on<LoadMoreMyCoursesEvent>(_onLoadMoreMyCourses);
    on<FilterByCategoryEvent>(_onFilterByCategory);
    on<FilterBySpecialtyEvent>(_onFilterBySpecialty);
    on<ClearFiltersEvent>(_onClearFilters);
    on<ClearCoursesStateEvent>(_onClearState);

    _subscriptionUpdatedListener = globalEventBus.on<SubscriptionUpdatedEvent>().listen((_) {
      if (!state.isMyCoursesMode) return;
      add(const LoadMyCoursesEvent(refresh: true));
    });
  }

  Future<void> _onLoadCourses(
    LoadCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final targetCategory = event.categoryId ?? state.categoryId;
    final targetSpecialty = event.specialtyId ?? state.specialtyId;
    final nextPage = event.page ?? 1;

    final shouldRefresh = event.refresh;
    final isInitial = state.items.isEmpty || shouldRefresh && !state.isRefreshing;

    emit(
      state.copyWith(
        isInitialLoading: isInitial && !shouldRefresh,
        isRefreshing: shouldRefresh,
        isLoadingMore: false,
        currentPage: nextPage,
        categoryId: targetCategory,
        specialtyId: targetSpecialty,
        isMyCoursesMode: false,
        clearError: true,
      ),
    );

    final result = await getCoursesUseCase(
      pagination: PaginationParams(page: nextPage, limit: event.perPage ?? _perPage),
      categoryId: targetCategory,
      specialtyId: targetSpecialty,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            errorMessage: failure.message,
          ),
        );
      },
      (pageData) {
        emit(
          state.copyWith(
            items: pageData.items,
            currentPage: pageData.page,
            hasMore: pageData.hasMore,
            isInitialLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreCourses(
    LoadMoreCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    if (state.isMyCoursesMode || state.isInitialLoading || state.isRefreshing || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final nextPage = state.currentPage + 1;
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final result = await getCoursesUseCase(
      pagination: PaginationParams(page: nextPage, limit: _perPage),
      categoryId: state.categoryId,
      specialtyId: state.specialtyId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingMore: false, errorMessage: failure.message));
      },
      (pageData) {
        emit(
          state.copyWith(
            items: [...state.items, ...pageData.items],
            currentPage: pageData.page,
            hasMore: pageData.hasMore,
            isLoadingMore: false,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onLoadCourseById(
    LoadCourseByIdEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final result = await getCourseByIdUseCase(id: event.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  Future<void> _onLoadMyCourses(
    LoadMyCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final shouldRefresh = event.refresh;
    final nextPage = event.page;

    emit(
      state.copyWith(
        isInitialLoading: state.items.isEmpty && !shouldRefresh,
        isRefreshing: shouldRefresh,
        isLoadingMore: false,
        currentPage: nextPage,
        isMyCoursesMode: true,
        clearError: true,
      ),
    );

    final result = await getMyCoursesUseCase(
      pagination: PaginationParams(page: nextPage, limit: _perPage),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            errorMessage: failure.message,
          ),
        );
      },
      (pageData) {
        emit(
          state.copyWith(
            items: event.page == 1 ? pageData.items : [...state.items, ...pageData.items],
            hasMore: pageData.hasMore,
            currentPage: pageData.page,
            isInitialLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreMyCourses(
    LoadMoreMyCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    if (!state.isMyCoursesMode || state.isInitialLoading || state.isRefreshing || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final nextPage = state.currentPage + 1;
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final result = await getMyCoursesUseCase(
      pagination: PaginationParams(page: nextPage, limit: _perPage),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingMore: false, errorMessage: failure.message));
      },
      (pageData) {
        emit(
          state.copyWith(
            items: [...state.items, ...pageData.items],
            currentPage: pageData.page,
            hasMore: pageData.hasMore,
            isLoadingMore: false,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onFilterByCategory(
    FilterByCategoryEvent event,
    Emitter<CoursesState> emit,
  ) async {
    _filterDebouncer.call(() {
      add(LoadCoursesEvent(categoryId: event.categoryId, refresh: true));
    });
  }

  Future<void> _onFilterBySpecialty(
    FilterBySpecialtyEvent event,
    Emitter<CoursesState> emit,
  ) async {
    _filterDebouncer.call(() {
      add(LoadCoursesEvent(specialtyId: event.specialtyId, refresh: true));
    });
  }

  Future<void> _onClearFilters(
    ClearFiltersEvent event,
    Emitter<CoursesState> emit,
  ) async {
    add(const LoadCoursesEvent(categoryId: null, specialtyId: null, refresh: true));
  }

  void _onClearState(
    ClearCoursesStateEvent event,
    Emitter<CoursesState> emit,
  ) {
    emit(const CoursesState());
  }

  @override
  Future<void> close() {
    _subscriptionUpdatedListener?.cancel();
    _filterDebouncer.dispose();
    return super.close();
  }
}
