import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_lms/features/shorts/domain/repositories/shorts_repository.dart';
import 'package:learnify_lms/features/shorts/domain/usecases/check_shorts_access_usecase.dart';
import 'package:learnify_lms/features/shorts/presentation/bloc/shorts_bloc.dart';
import 'package:learnify_lms/features/shorts/presentation/bloc/shorts_event.dart';
import 'package:learnify_lms/features/shorts/presentation/bloc/shorts_state.dart';

class _FakeShortsRepository implements ShortsRepository {
  int viewedCount;
  final Set<int> viewedReels;

  _FakeShortsRepository({
    this.viewedCount = 0,
    Set<int>? viewedReels,
  }) : viewedReels = viewedReels ?? <int>{};

  @override
  Future<int> getViewedShortsCount() async => viewedCount;

  @override
  Future<bool> hasViewedReel(int reelId) async => viewedReels.contains(reelId);

  @override
  Future<void> markReelViewed(int reelId) async {
    if (viewedReels.add(reelId)) {
      viewedCount++;
    }
  }

  @override
  Future<void> resetViewedReels() async {
    viewedCount = 0;
    viewedReels.clear();
  }
}

void main() {
  group('ShortsBloc', () {
    test('emits loaded when below limit', () async {
      final repository = _FakeShortsRepository();
      final bloc = ShortsBloc(
        repository: repository,
        checkShortsAccessUseCase: CheckShortsAccessUseCase(repository),
      );

      final emitted = <ShortsState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const LoadShortsAccessEvent(isSubscribed: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted, [
        const ShortsLoading(),
        const ShortsLoaded(
          viewedCount: 0,
          freeThreshold: 10,
          isLimitEnabled: true,
        ),
      ]);

      await sub.cancel();
      await bloc.close();
    });

    test('does not lock during the video that hits the threshold', () async {
      // User has watched 9 videos. Watching the 10th (reel 11) should emit
      // ShortsLoaded so the user can finish it. The lock only surfaces when
      // they try to start a NEW video after exhausting the trial (reel 12).
      final repository = _FakeShortsRepository(
        viewedCount: 9,
        viewedReels: {1, 2, 3, 4, 5, 6, 7, 8, 9},
      );
      final bloc = ShortsBloc(
        repository: repository,
        checkShortsAccessUseCase: CheckShortsAccessUseCase(repository),
      );

      final emitted = <ShortsState>[];
      final sub = bloc.stream.listen(emitted.add);

      // 10th video: canWatch = true (9 < 10) → marked → ShortsLoaded(count:10)
      bloc.add(const MarkShortViewedEvent(reelId: 11, isSubscribed: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted.last, const ShortsLoaded(
        viewedCount: 10,
        freeThreshold: 10,
        isLimitEnabled: true,
      ));

      // 11th video attempt: canWatch = false (10 < 10 is false) → ShortsLocked
      bloc.add(const MarkShortViewedEvent(reelId: 12, isSubscribed: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted.last, const ShortsLocked(
        viewedCount: 10,
        freeThreshold: 10,
        isLimitEnabled: true,
      ));

      await sub.cancel();
      await bloc.close();
    });

    test('does not increase viewed count for duplicate reel id', () async {
      final repository = _FakeShortsRepository(
        viewedCount: 1,
        viewedReels: {7},
      );
      final bloc = ShortsBloc(
        repository: repository,
        checkShortsAccessUseCase: CheckShortsAccessUseCase(repository),
      );

      final emitted = <ShortsState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const MarkShortViewedEvent(reelId: 7, isSubscribed: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
          emitted.last,
          const ShortsLoaded(
            viewedCount: 1,
            freeThreshold: 10,
            isLimitEnabled: true,
          ));
      expect(repository.viewedReels.length, 1);

      await sub.cancel();
      await bloc.close();
    });
  });
}
