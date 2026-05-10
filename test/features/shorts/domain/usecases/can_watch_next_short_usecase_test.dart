import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_lms/features/shorts/domain/usecases/check_shorts_access_usecase.dart';

void main() {
  group('CheckShortsAccessUseCase', () {
    test('returns true for subscribed user', () async {
      const useCase = CheckShortsAccessUseCase();

      final result = await useCase(isSubscribed: true);

      expect(result, isTrue);
    });

    test('returns false for non-subscribed user', () async {
      const useCase = CheckShortsAccessUseCase();

      final result = await useCase(isSubscribed: false);

      expect(result, isFalse);
    });
  });
}
