import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/presentation/pages/main_navigation_page.dart';
import '../../../reels/presentation/bloc/reels_bloc.dart';
import '../../../reels/presentation/bloc/reels_event.dart';
import '../../../reels/presentation/pages/reels_feed_page.dart';

class ShortsPage extends StatefulWidget {
  final int? initialIndex;

  static int? _pendingInitialIndex;
  
  static void setInitialIndex(int? index) {
    _pendingInitialIndex = index;
  }
  
  static int? getInitialIndex() {
    final index = _pendingInitialIndex;
    _pendingInitialIndex = null;
    return index;
  }
  
  const ShortsPage({super.key, this.initialIndex});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  ReelsBloc? _reelsBloc;
  bool _hasLoadedOnce = false;
  bool _isActive = false;
  TabIndexNotifier? _tabNotifier;
  int? _initialIndex;

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.initialIndex ?? ShortsPage.getInitialIndex();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = TabIndexProvider.of(context);
    if (notifier != null && _tabNotifier != notifier) {
      _tabNotifier?.removeListener(_onTabChanged);
      _tabNotifier = notifier;
      _tabNotifier!.addListener(_onTabChanged);
      final newIsActive = _tabNotifier!.value == 1;
      if (_isActive != newIsActive) {
        _isActive = newIsActive;
      }
    }
  }

  void _onTabChanged() {
    if (_tabNotifier != null && mounted) {
      final newIsActive = _tabNotifier!.value == 1;
      if (_isActive != newIsActive) {
        setState(() {
          _isActive = newIsActive;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabNotifier?.removeListener(_onTabChanged);
    _reelsBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoadedOnce) {
      if (_isActive) {
        _hasLoadedOnce = true;
        final pendingIndex = ShortsPage.getInitialIndex();
        if (pendingIndex != null && _initialIndex == null) {
          _initialIndex = pendingIndex;
        }
      } else {
        return const ColoredBox(color: Colors.black);
      }
    }

    final effectiveInitialIndex = _initialIndex ?? 0;

    if (_reelsBloc != null) {
      return BlocProvider.value(
        key: const ValueKey('shorts_reels_bloc_provider'),
        value: _reelsBloc!,
        child: ReelsFeedPage(
          key: ValueKey('shorts_reels_feed_$effectiveInitialIndex'),
          initialIndex: effectiveInitialIndex,
          showBackButton: false,
          freeReelsLimit: 5,
          isTabActive: _isActive,
        ),
      );
    }

    return BlocProvider(
      key: const ValueKey('shorts_reels_bloc_provider_new'),
      create: (_) {
        _reelsBloc = sl<ReelsBloc>()..add(const LoadReelsFeedEvent(perPage: 5));
        return _reelsBloc!;
      },
      child: ReelsFeedPage(
        key: ValueKey('shorts_reels_feed_$effectiveInitialIndex'),
        initialIndex: effectiveInitialIndex,
        showBackButton: false,
        freeReelsLimit: 5,
        isTabActive: _isActive,
      ),
    );
  }
}


