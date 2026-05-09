import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_lms/features/shorts/domain/usecases/check_shorts_access_usecase.dart';
import 'package:learnify_lms/features/shorts/presentation/bloc/shorts_bloc.dart';
import 'package:learnify_lms/features/shorts/presentation/bloc/shorts_event.dart';
import 'package:learnify_lms/features/shorts/presentation/bloc/shorts_state.dart';

void main() {
  group('ShortsBloc', () {
    test('emits loaded for subscribed user', () async {
      final bloc = ShortsBloc(
        checkShortsAccessUseCase: const CheckShortsAccessUseCase(),
      );

      final emitted = <ShortsState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const LoadShortsAccessEvent(isSubscribed: true));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted, [
        const ShortsLoading(),
        const ShortsLoaded(),
      ]);

      await sub.cancel();
      await bloc.close();
    });

    test('emits locked for non-subscribed user', () async {
      final bloc = ShortsBloc(
        checkShortsAccessUseCase: const CheckShortsAccessUseCase(),
      );

      final emitted = <ShortsState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const LoadShortsAccessEvent(isSubscribed: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted, [
        const ShortsLoading(),
        const ShortsLocked(),
      ]);

      await sub.cancel();
      await bloc.close();
    });
  });
}
