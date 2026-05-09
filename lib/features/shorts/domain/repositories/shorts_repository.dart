abstract class ShortsRepository {
  Future<int> getViewedShortsCount();
  Future<bool> hasViewedReel(int reelId);
  Future<void> markReelViewed(int reelId);
  Future<void> resetViewedReels();
}
