import '../../../../core/storage/hive_service.dart';

class ShortsConfigService {
  final HiveService hiveService;

  static const String _viewedReelsKey = 'shorts_viewed_reel_ids';

  const ShortsConfigService(this.hiveService);

  Future<Set<int>> getViewedReelIds() async {
    final stored = await hiveService.getData(_viewedReelsKey);
    if (stored is List) {
      return stored.whereType<num>().map((e) => e.toInt()).toSet();
    }
    return <int>{};
  }

  Future<int> getViewedShortsCount() async {
    final viewedIds = await getViewedReelIds();
    return viewedIds.length;
  }

  Future<void> saveViewedShortsCount(int count) async {
    // Keep this as no-op for compatibility with existing call sites.
    // The source of truth is `shorts_viewed_reel_ids`.
  }

  Future<void> saveViewedReelIds(Set<int> reelIds) async {
    await hiveService.saveData(_viewedReelsKey, reelIds.toList());
  }

  Future<void> resetViewedReels() async {
    await hiveService.deleteData(_viewedReelsKey);
  }
}
