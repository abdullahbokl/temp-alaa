class CheckShortsAccessUseCase {
  const CheckShortsAccessUseCase();

  Future<bool> call({required bool isSubscribed}) async {
    return isSubscribed;
  }
}
