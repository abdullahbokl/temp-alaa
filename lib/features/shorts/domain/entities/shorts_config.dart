import 'package:equatable/equatable.dart';

class ShortsConfig extends Equatable {
  final bool isLimitEnabled;
  final int freeVideoCount;

  const ShortsConfig({
    required this.isLimitEnabled,
    required this.freeVideoCount,
  });

  const ShortsConfig.defaults()
      : isLimitEnabled = true,
        freeVideoCount = 10;

  ShortsConfig copyWith({
    bool? isLimitEnabled,
    int? freeVideoCount,
  }) {
    return ShortsConfig(
      isLimitEnabled: isLimitEnabled ?? this.isLimitEnabled,
      freeVideoCount: freeVideoCount ?? this.freeVideoCount,
    );
  }

  @override
  List<Object?> get props => [isLimitEnabled, freeVideoCount];
}
