# Learnify LMS: Optimization & Feature Expansion Design

Date: 2026-05-09

## Overview

Four critical areas for Learnify LMS: 401 auth fix, lazy loading/pagination, performance audit, and shorts optimization.

---

## 1. Fix: Persistent 401 Unauthorized Errors (Guest Mode + Token Refresh)

### Root Causes

1. `_AuthInterceptor` sends `protected` requests without token. No rejection. Server returns 401.
2. No token refresh mechanism. `refresh_token` stored but never used.
3. No UI gate. Guests navigate to protected screens freely.
4. `reels/` and `reel-categories/` are `protected` prefixes. Guests blocked from shorts.

### Architecture: Layer Changes

| Layer | File | Change |
|-------|------|--------|
| Core/Network | `dio_client.dart` | Rewrite `_AuthInterceptor` with 3-path logic |
| Core/Network | `request_auth.dart` | Add `guest` AuthRequirement level |
| Core/Network | NEW `token_refresh_interceptor.dart` | Separate interceptor for 401 retry + refresh |
| Core/Storage | `secure_storage_service.dart` | Add `getRefreshToken()` method |
| Domain | NEW `refresh_token_usecase.dart` | Domain use case for token refresh |
| Data | `auth_remote_datasource.dart` | Add `refreshToken()` method |
| Data | `auth_repository_impl.dart` | Wire refresh use case |
| Presentation | `app_router.dart` | Auth guard on protected routes |
| Presentation | Feature BLoCs | Remove ad-hoc 401 handling from individual BLoCs |

### Interceptor Flow (Redesigned)

```
Request arrives
  |
  v
_withAuthOptions resolves AuthRequirement:
  public    -> skip auth header
  optional  -> attach token if exists, else guest header
  guest     -> skip auth header (explicitly guest-accessible)
  protected -> check token existence:
    HAS token -> attach Bearer header
    NO token  -> REJECT immediately with DioException(401)
                 (never sends to server)
  |
  v
TokenRefreshInterceptor.onError:
  if 401 AND has refresh_token AND not already retrying:
    lock request queue
    call /auth/refresh with refresh_token
    if success -> save new access_token, retry all queued requests
    if fail -> clear tokens, emit AuthSessionExpired, reject all queued
  else:
    forward error
```

### AuthRequirement: Add `guest` Level

```dart
enum AuthRequirement {
  public,    // No auth ever (login, register, homeAPI)
  optional,  // Auth if available, guest if not (courses listing)
  guest,     // Explicitly guest-accessible (reels feed preview)
  protected, // Must be authenticated (myCourses, profile)
}
```

Routes currently under `reels/` and `reel-categories/` prefixes become `guest` or `optional` so guests can see limited shorts content. The existing `freeReelsLimit` paywall in ReelsFeedPage handles guest throttling at the presentation layer.

### _AuthInterceptor.onRequest (Redesigned)

```dart
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  final authRequirement = options.extra[RequestAuthMeta.authRequirementKey];
  final token = await _secureStorage.getAccessToken();

  switch (authRequirement) {
    case AuthRequirement.public:
    case AuthRequirement.guest:
      options.extra['auth_attached'] = false;
      handler.next(options);
      break;
    case AuthRequirement.optional:
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra['auth_attached'] = true;
      } else {
        options.extra['auth_attached'] = false;
      }
      handler.next(options);
      break;
    case AuthRequirement.protected:
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra['auth_attached'] = true;
        handler.next(options);
      } else {
        // REJECT immediately — never send to server
        handler.reject(DioException(
          requestOptions: options,
          error: 'Authentication required',
          type: DioExceptionType.unknown,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            statusMessage: 'Unauthorized',
          ),
        ));
      }
      break;
  }
}
```

### TokenRefreshInterceptor

Separate interceptor placed AFTER `_AuthInterceptor` in the chain. Handles 401 errors from authenticated sessions where the access token expired.

```dart
class TokenRefreshInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  // IMPORTANT: _dio must be a BARE Dio instance with NO interceptors
  // to avoid infinite recursion when the refresh call itself fails.
  // Use Dio() directly, not the app's DioClient instance.
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final Dio _mainDio; // app's DioClient for retrying queued requests
  bool _isRefreshing = false;
  final List<_RetryRequest> _requestQueue = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        _secureStorage.getRefreshToken() != null &&
        !_isTokenRefreshRequest(err.requestOptions)) {
      if (_isRefreshing) {
        // Queue the request to retry after refresh completes
        _requestQueue.add(_RetryRequest(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;
      try {
        final newToken = await _performRefresh();
        // Retry original request
        final retryOptions = err.requestOptions.copyWith(
          headers: {'Authorization': 'Bearer $newToken'},
        );
        final response = await _dio.fetch(retryOptions);
        handler.resolve(response);
        // Retry queued requests
        _retryQueuedRequests(newToken);
      } catch (e) {
        // Refresh failed — clear tokens, emit session expired
        await _secureStorage.clearAll();
        _rejectQueuedRequests();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<String> _performRefresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    final response = await _dio.post(
      ApiConstants.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    final newAccessToken = response.data['access_token'];
    final newRefreshToken = response.data['refresh_token'];
    await _secureStorage.saveAccessToken(newAccessToken);
    await _secureStorage.saveRefreshToken(newRefreshToken);
    return newAccessToken;
  }
}
```

### Route Guard Pattern

```dart
// app_router.dart
GoRoute(
  path: '/my-courses',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return '/login';
    return null;
  },
  builder: (_, __) => const MyCoursesPage(),
),
```

Protected routes that need guards: `/my-courses`, `/profile`, `/certificates`, `/subscriptions`, `/transactions`, `/settings`.

### RequestAuth Policy Updates

Move from `protectedPrefixes` to `optionalPaths` or new `guestPaths`:
- `reels/` -> `guestPaths` (guests can view limited feed)
- `reel-categories/` -> `guestPaths` (guests can see categories)
- `recordReelView` -> `optionalPaths` (best-effort view tracking)

---

## 2. Optimization: Lazy Loading & Pagination

### Current State

| Feature | Pagination | Pattern |
|---------|-----------|---------|
| Home | None | Single `GET homeAPI`, all lists at once |
| Courses (browse) | Page-based | `getCourses(pagination)` + `LoadMoreCoursesEvent` |
| Courses (my) | None | `getMyCourses()` all-at-once, `hasMore: false` |
| Reels | Cursor-based | Already working |

### Architecture: Layer Changes

| Layer | File | Change |
|-------|------|--------|
| Core | `pagination_params.dart` | Already exists. No change. |
| Core | `paginated_list.dart` | Already exists. No change. |
| Data/Home | `home_remote_datasource.dart` | Split `getHomeData()` into section methods |
| Data/Home | NEW `home_api_constants.dart` | Section endpoint constants |
| Domain/Home | `home_repository.dart` | Add per-section repository methods |
| Domain/Home | NEW use cases | `GetLatestCoursesUseCase`, `GetFreeCoursesUseCase`, `GetPopularCoursesUseCase` |
| Presentation/Home | `home_bloc.dart` | Per-section events/states, `LoadMore` per section |
| Presentation/Home | `home_tab.dart` | Section-level `LoadMore` scroll triggers |
| Data/Courses | `course_remote_datasource.dart` | Add pagination to `getMyCourses()` |
| Presentation/Courses | `courses_bloc.dart` | Add `LoadMoreMyCoursesEvent` |

### Home: Per-Section Endpoints

Current: `getHomeData()` -> `GET homeAPI` -> returns everything.

Proposed: Home page keeps `getHomeData()` for initial load (banners + topMentors + partners — small, static data). Each course section gets its own paginated endpoint.

```dart
// home_remote_datasource.dart
Future<HomeData> getHomeData(); // banners, mentors, partners only
Future<PaginatedList<Course>> getLatestCourses({required PaginationParams pagination});
Future<PaginatedList<Course>> getFreeCourses({required PaginationParams pagination});
Future<PaginatedList<Course>> getPopularCourses({required PaginationParams pagination});
Future<PaginatedList<CategoryCourseBlock>> getCategoryCourseBlocks({
  required PaginationParams pagination,
});
```

### Home BLoC: Per-Section Pagination

```dart
// home_event.dart
class LoadHomeDataEvent extends HomeEvent {} // initial: banners + mentors + partners
class LoadLatestCoursesEvent extends HomeEvent { final int page; }
class LoadMoreLatestCoursesEvent extends HomeEvent {}
class LoadFreeCoursesEvent extends HomeEvent { final int page; }
class LoadMoreFreeCoursesEvent extends HomeEvent {}
class LoadPopularCoursesEvent extends HomeEvent { final int page; }
class LoadMorePopularCoursesEvent extends HomeEvent {}

// home_state.dart
class HomeLoaded extends HomeState {
  final HomeData homeData; // banners, mentors, partners
  final PaginatedList<Course> latestCourses;
  final PaginatedList<Course> freeCourses;
  final PaginatedList<Course> popularCourses;
  final bool isLoadingMoreLatest;
  final bool isLoadingMoreFree;
  final bool isLoadingMorePopular;
}
```

### myCourses: Page-Based Pagination

```dart
// course_remote_datasource.dart
Future<PaginatedList<Course>> getMyCourses({
  required PaginationParams pagination,
});
// Sends: GET myCourses?page={page}&per_page={perPage}

// courses_event.dart
class LoadMyCoursesEvent extends CoursesEvent {
  final int page;
  final bool refresh;
}
class LoadMoreMyCoursesEvent extends CoursesEvent {}

// courses_state.dart — update CoursesState
class CoursesState {
  // existing fields...
  final List<Course> myCoursesItems;
  final bool isLoadingMoreMyCourses;
  final bool hasMoreMyCourses;
  final int myCoursesCurrentPage;
}
```

### UI Pattern: LoadMore Trigger (Reusable)

All sections use the same pattern already established in `all_courses_page.dart`:

```dart
NotificationListener<ScrollNotification>(
  onNotification: (scroll) {
    if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
      final state = context.read<HomeBloc>().state;
      if (state is HomeLoaded && !state.isLoadingMoreLatest && state.latestCourses.hasMore) {
        context.read<HomeBloc>().add(LoadMoreLatestCoursesEvent());
      }
    }
    return false;
  },
  child: ListView.builder(...),
)
```

### Pagination Flow

```
Home page loads
  |
  v
LoadHomeDataEvent -> fetches banners + mentors + partners (lightweight)
  |
  v (parallel)
LoadLatestCoursesEvent(page:1)  LoadFreeCoursesEvent(page:1)  LoadPopularCoursesEvent(page:1)
  |                               |                             |
  v                               v                             v
HomeLoaded with initial sections (10 items each)
  |
  v (user scrolls to end of a section)
LoadMoreLatestCoursesEvent -> fetches page 2 -> appends to latestCourses.items
```

---

## 3. Audit: Performance, Smoothness & UI Polish

### Critical Issues

| Issue | Severity | Locations |
|-------|----------|-----------|
| `shrinkWrap:true + NeverScrollableScrollPhysics` | High | 7 files: tablet_home_tab (4x), course_details_page, certificates_page, tablet_menu_page |
| Zero `AutomaticKeepAliveClientMixin` | High | All tab views lose state on switch |
| Missing `memCacheWidth/Height` | High | 10 files: single_category_page, popular_courses_page, categories_page, course_details_page, banner_carousel, site_banner_carousel, collected_reels_page, course_circle_item, lesson_player_page, tablet_home_tab |
| 12+ different placeholder patterns | Medium | Across all image-using files |
| Sparse `RepaintBoundary` (4 usages) | Medium | Missing on complex card widgets |

### Fix 1: Eliminate shrinkWrap Anti-Pattern

Replace nested `GridView` with `shrinkWrap:true` to `CustomScrollView` + `SliverGrid`:

```dart
// Before: Eager builds ALL children
GridView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: 100,
  ...
)

// After: Lazy builds only visible children
CustomScrollView(
  slivers: [
    SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => CourseCard(course: courses[index]),
        childCount: courses.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
      ),
    ),
  ],
)
```

Affected files:
- `tablet_home_tab.dart` (4 GridView instances)
- `course_details_page.dart` (1 GridView)
- `certificates_page.dart` (1 ListView)
- `tablet_menu_page.dart` (1 GridView)

### Fix 2: AutomaticKeepAliveClientMixin for Tabs

```dart
class HomeTab extends StatefulWidget {
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required
    return ...;
  }
}
```

Applied to: home_tab, all_courses_page, categories_page, popular_courses_page, reels_feed_page, and all tab children in tablet_home_tab.

### Fix 3: OptimizedImage Shared Widget

Single reusable widget replacing 12+ placeholder patterns:

```dart
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    super.key,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memW = width != null ? (width! * dpr).toInt() : null;
    final memH = height != null ? (height! * dpr).toInt() : null;

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memW,
      memCacheHeight: memH,
      placeholder: (_, __) => _defaultPlaceholder(),
      errorWidget: (_, __, ___) =>
          errorWidget ?? _defaultErrorWidget(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _defaultPlaceholder() => Container(
    width: width,
    height: height,
    color: Colors.grey[100],
    child: Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _defaultErrorWidget() => Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: Icon(Icons.image_outlined, color: Colors.grey[400]),
  );
}
```

### Fix 4: RepaintBoundary Wrapping

Add to high-cost widgets:
- Course cards in GridView items
- Reel thumbnails in grids
- Banner carousel items
- Widgets with shadows, gradients, clip paths

```dart
RepaintBoundary(
  child: CourseCard(course: course),
)
```

### DevTools Profiling Workflow

1. `flutter run --profile` (never debug mode for perf)
2. DevTools -> Performance panel -> record interactions
3. Check for frames > 16ms (60fps) or > 8ms (120fps)
4. DevTools -> Memory panel -> snapshot before/after scrolling large lists
5. DevTools -> CPU Profiler -> identify jank in build/layout/paint phases
6. `flutter run --trace-startup` for initialization cost measurement

---

## 4. Feature: Shorts Integration (Fix & Optimize Existing)

### Current State

The reels/shorts system is already fully implemented. Issues to fix:

| Issue | File | Detail |
|-------|------|--------|
| `reels/` is `protected` prefix | `request_auth.dart` | No guest access to shorts |
| `ShortVideo` entity + `ShortsGrid` unused | `lib/features/shorts/` | Dead code confusion |
| ReelsFeedPage is 1382 lines | `reels_feed_page.dart` | Monolithic, hard to maintain |
| No pre-buffering beyond next video | `reel_player_widget.dart` | Only preloads 1 ahead |
| Fast-swipe race conditions | `reel_controller_pool.dart` | No lock on setDataSource |

### Fix 1: Guest Access

Move `reels/` and `reel-categories/` from `protectedPrefixes` to new `guestPaths` in `request_auth.dart`. Guest users see limited feed (existing `freeReelsLimit` paywall at 5 reels already handles throttling at presentation layer).

### Fix 2: Remove Legacy Shorts Code

Delete:
- `lib/features/shorts/domain/entities/short_video.dart`
- `lib/features/shorts/presentation/widgets/shorts_grid.dart`

Keep:
- `ShortsPage` (thin wrapper around ReelsFeedPage)
- `TabletShortsPage` (tablet variant)

### Fix 3: Decompose ReelsFeedPage (1382 lines)

Extract into:

| Widget | Responsibility | Lines (est.) |
|--------|---------------|-------------|
| `ReelFeedAppBar` | Category filters + header | ~80 |
| `ReelFeedItem` | Single page in PageView (visibility, paywall, auth gate) | ~250 |
| `ReelPlaybackController` | Slot-to-index mapping, page change debounce | ~120 |
| `ReelFeedPagination` | Cursor-based load-more logic | ~60 |
| `ReelsFeedPage` | Composition root | ~200 |

### Fix 4: Pre-buffering Improvement

Current: preloads only `nextIndex = currentIndex + 1`.

Enhanced: Preload `currentIndex + 1` and `currentIndex + 2` (warm up recycled slot when page stabilizes).

```dart
// reel_player_widget.dart
_preloadNext() {
  // existing: preloads next reel into available slot
}

_preloadAhead() {
  // NEW: after page stabilizes (300ms debounce),
  // warm up the recycled slot (from currentIndex - 1)
  // with currentIndex + 2 data
  _preloadDebouncer?.cancel();
  _preloadDebouncer = Timer(const Duration(milliseconds: 300), () {
    final aheadIndex = _currentIndex + 2;
    if (aheadIndex < widget.reels.length) {
      final availableSlot = (_currentSlot + 2) % maxControllers;
      _controllerPool.warmUp(availableSlot, widget.reels[aheadIndex].bunnyUrl);
    }
  });
}
```

### Fix 5: Fast-Swipe Safety

Add `Completer`-based locking to `ReelControllerPool.setDataSource()`:

```dart
class ReelControllerPool {
  static const maxControllers = 3;
  final List<BetterPlayerController?> _controllers = List.filled(maxControllers, null);
  final List<Completer<void>?> _initLocks = List.filled(maxControllers, null);

  Future<void> setDataSource(int slot, String url) async {
    // Wait if this slot is already initializing
    if (_initLocks[slot] != null) {
      await _initLocks[slot]!.future;
    }

    _initLocks[slot] = Completer<void>();
    try {
      final controller = _controllers[slot];
      if (controller != null) {
        final hlsUrl = ReelUrlHelper.toBunnyHlsUrl(url);
        await controller.setupDataSource(
          BetterPlayerDataSource(
            BetterPlayerDataSourceType.network,
            hlsUrl,
            notificationConfiguration: BetterPlayerNotificationConfiguration(
              showNotification: false,
            ),
          ),
        );
      }
    } finally {
      _initLocks[slot]!.complete();
      _initLocks[slot] = null;
    }
  }
}
```

---

## Implementation Order

1. **401 Fix** (highest priority — blocks guests, causes error spam)
   - AuthRequirement `guest` level + route classification
   - _AuthInterceptor rewrite with immediate rejection
   - TokenRefreshInterceptor + refresh endpoint integration
   - Route guards on protected paths
2. **Lazy Loading** (high priority — causes startup lag)
   - Home per-section endpoints + BLoC refactor
   - myCourses page-based pagination
   - Section-level LoadMore scroll triggers in UI
3. **Performance** (medium priority — UX polish)
   - Eliminate shrinkWrap anti-patterns
   - AutomaticKeepAliveClientMixin for tabs
   - OptimizedImage shared widget
   - RepaintBoundary additions
4. **Shorts Optimization** (medium priority — feature completion)
   - Guest access for reels
   - Legacy code cleanup
   - ReelsFeedPage decomposition
   - Pre-buffering enhancement
   - Fast-swipe safety lock
