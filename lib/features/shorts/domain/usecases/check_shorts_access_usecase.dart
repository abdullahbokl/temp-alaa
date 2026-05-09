import '../../../../core/config/app_config.dart';
import '../repositories/shorts_repository.dart';

class CheckShortsAccessUseCase {
  final ShortsRepository repository;

  const CheckShortsAccessUseCase(this.repository);

  Future<bool> call({required bool isSubscribed}) async {
    if (isSubscribed) return true;
    if (!AppConfig.enableShortsLimit) return true;

    final viewedCount = await repository.getViewedShortsCount();
    return viewedCount < AppConfig.freeShortsThreshold;
  }
}
