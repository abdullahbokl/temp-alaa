import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router.dart';
import '../../../authentication/data/datasources/auth_local_datasource.dart';
import '../../../home/presentation/pages/main_navigation_page.dart';
import '../../../reels/presentation/bloc/reels_bloc.dart';
import '../../../reels/presentation/bloc/reels_event.dart';
import '../../../reels/presentation/pages/reels_feed_page.dart';
import '../bloc/shorts_bloc.dart';
import '../bloc/shorts_event.dart';
import '../bloc/shorts_state.dart';

import '../widgets/shorts_lock_overlay.dart';

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
  ShortsBloc? _shortsBloc;
  bool _hasLoadedOnce = false;
  bool _isActive = false;
  bool _isSubscribed = false;
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

  Future<void> _bootstrapShortsAccess() async {
    try {
      final user = await sl<AuthLocalDataSource>().getCachedUser();
      if (!mounted) return;
      _isSubscribed = user?.isSubscribed == true;
    } catch (_) {
      _isSubscribed = false;
    }
    _shortsBloc?.add(LoadShortsAccessEvent(isSubscribed: _isSubscribed));
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
    _shortsBloc?.close();
    super.dispose();
  }

  Future<void> _openSubscription() async {
    final mainNav = context.mainNavigation;
    if (mainNav != null) {
      mainNav.setShowBottomNav(true);
      mainNav.switchToTab(2);
      return;
    }
    await Navigator.of(context, rootNavigator: true)
        .pushNamed(AppRouter.subscriptions);
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

    if (_shortsBloc == null) {
      _shortsBloc = sl<ShortsBloc>();
      _bootstrapShortsAccess();
    }

    return BlocProvider<ShortsBloc>.value(
      value: _shortsBloc!,
      child: BlocBuilder<ShortsBloc, ShortsState>(
        builder: (context, shortsState) {
          if (shortsState is ShortsLoading) {
            return const ColoredBox(color: Colors.black);
          }

          if (shortsState is ShortsLocked) {
            return Stack(
              children: [
                const ColoredBox(color: Colors.black),
                Positioned.fill(
                  child: ShortsLockOverlay(onSubscribe: _openSubscription),
                ),
              ],
            );
          }

          _reelsBloc ??= sl<ReelsBloc>()
            ..add(const LoadReelsFeedEvent(perPage: 5));

          return BlocProvider<ReelsBloc>.value(
            value: _reelsBloc!,
            child: ReelsFeedPage(
              key: ValueKey('shorts_reels_feed_$effectiveInitialIndex'),
              initialIndex: effectiveInitialIndex,
              showBackButton: false,
              freeReelsLimit: 0,
              isLimitEnabled: false,
              forceLocked: false,
              isTabActive: _isActive,
              onReelViewed: (_) {},
            ),
          );
        },
      ),
    );
  }
}
