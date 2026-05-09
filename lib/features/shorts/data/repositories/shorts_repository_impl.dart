import '../../domain/repositories/shorts_repository.dart';
import '../services/shorts_config_service.dart';

class ShortsRepositoryImpl implements ShortsRepository {
  final ShortsConfigService service;

  const ShortsRepositoryImpl(this.service);

  @override
  Future<int> getViewedShortsCount() => service.getViewedShortsCount();

  @override
  Future<bool> hasViewedReel(int reelId) async {
    final viewed = await service.getViewedReelIds();
    return viewed.contains(reelId);
  }

  @override
  Future<void> markReelViewed(int reelId) async {
    final viewed = await service.getViewedReelIds();
    if (viewed.contains(reelId)) return;

    viewed.add(reelId);
    await service.saveViewedReelIds(viewed);
    await service.saveViewedShortsCount(viewed.length);
  }

  @override
  Future<void> resetViewedReels() => service.resetViewedReels();
}
