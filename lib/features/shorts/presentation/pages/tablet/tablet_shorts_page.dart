import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/routing/app_router.dart';
import '../../../../authentication/data/datasources/auth_local_datasource.dart';
import '../../../../home/presentation/pages/main_navigation_page.dart';
import '../../../../reels/presentation/bloc/reels_bloc.dart';
import '../../../../reels/presentation/bloc/reels_event.dart';
import '../../../../reels/presentation/pages/reels_feed_page.dart';
import '../../bloc/shorts_bloc.dart';
import '../../bloc/shorts_event.dart';
import '../../bloc/shorts_state.dart';
import '../../widgets/shorts_lock_overlay.dart';

class TabletShortsPage extends StatefulWidget {
  final int? initialIndex;

  const TabletShortsPage({super.key, this.initialIndex});

  @override
  State<TabletShortsPage> createState() => _TabletShortsPageState();
}

class _TabletShortsPageState extends State<TabletShortsPage> {
  ReelsBloc? _reelsBloc;
  ShortsBloc? _shortsBloc;
  bool _hasLoadedOnce = false;
  bool _isSubscribed = false;

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

  @override
  void dispose() {
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
      _hasLoadedOnce = true;
      _shortsBloc = sl<ShortsBloc>();
      _bootstrapShortsAccess();
    }

    return BlocProvider<ShortsBloc>.value(
      value: _shortsBloc!,
      child: BlocBuilder<ShortsBloc, ShortsState>(
        builder: (context, shortsState) {
          if (shortsState is ShortsLoading) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: SizedBox.expand(),
            );
          }

          if (shortsState is ShortsLocked) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  const SizedBox.expand(),
                  Positioned.fill(
                    child: ShortsLockOverlay(onSubscribe: _openSubscription),
                  ),
                ],
              ),
            );
          }

          _reelsBloc ??= sl<ReelsBloc>()
            ..add(const LoadReelsFeedEvent(perPage: 10));

          return Scaffold(
            backgroundColor: Colors.black,
            body: BlocProvider<ReelsBloc>.value(
              value: _reelsBloc!,
              child: ReelsFeedPage(
                initialIndex: widget.initialIndex ?? 0,
                showBackButton: false,
                freeReelsLimit: 0,
                isLimitEnabled: false,
                forceLocked: false,
                isTabActive: true,
                onReelViewed: (_) {},
              ),
            ),
          );
        },
      ),
    );
  }
}
