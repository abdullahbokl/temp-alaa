import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_lms/features/shorts/domain/repositories/shorts_repository.dart';
import 'package:learnify_lms/features/shorts/domain/usecases/check_shorts_access_usecase.dart';

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
  group('CheckShortsAccessUseCase', () {
    test('returns true for subscribed user', () async {
      final repo = _FakeShortsRepository(
        viewedCount: 500,
      );
      final useCase = CheckShortsAccessUseCase(repo);

      final result = await useCase(isSubscribed: true);

      expect(result, isTrue);
    });

    test('returns false when viewed reaches free limit', () async {
      final repo = _FakeShortsRepository(
        viewedCount: 10,
      );
      final useCase = CheckShortsAccessUseCase(repo);

      final result = await useCase(isSubscribed: false);

      expect(result, isFalse);
    });

    test('returns true when viewed below free limit', () async {
      final repo = _FakeShortsRepository(
        viewedCount: 3,
      );
      final useCase = CheckShortsAccessUseCase(repo);

      final result = await useCase(isSubscribed: false);

      expect(result, isTrue);
    });
  });
}
