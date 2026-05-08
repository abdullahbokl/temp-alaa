import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/about/presentation/pages/about_page.dart';
import '../../features/onboarding/presentation/pages/content_preferences_page.dart';
import '../../features/authentication/presentation/pages/email_verification_page.dart';
import '../../features/authentication/presentation/pages/register/complete_profile_page.dart';
import '../../features/authentication/presentation/pages/forgot_password/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/forgot_password/otp_verification_page.dart';
import '../../features/authentication/presentation/pages/login/login_page.dart';
import '../../features/authentication/presentation/pages/register/register_page.dart';
import '../../features/certificates/presentation/pages/certificates_page.dart';
import '../../features/courses/presentation/pages/all_courses_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lessons/presentation/pages/lesson_player_page.dart';
import '../../features/menu/presentation/pages/menu_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reels/presentation/bloc/reels_bloc.dart';
import '../../features/reels/presentation/bloc/reels_event.dart';
import '../../features/reels/presentation/pages/reels_feed_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/subscriptions/presentation/pages/subscriptions_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../di/injection_container.dart';
import '../utils/responsive.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String createNewPassword = '/create-new-password';
  static const String otpVerification = '/otp-verification';
  static const String emailVerification = '/email-verification';
  static const String changePassword = '/change-password';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String menu = '/menu';
  static const String profile = '/profile';
  static const String subscriptions = '/subscriptions';
  static const String certificates = '/certificates';
  static const String transactions = '/transactions';
  static const String courses = '/courses';
  static const String lesson = '/lesson';
  static const String about = '/about';
  static const String reelsFeed = '/reels-feed';
  static const String contentPreferences = '/content-preferences';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case login:
        return _buildAuthPageRoute(
          const LoginPage(),
          fromRight: false,
        );

      case register:
        return _buildAuthPageRoute(
          const RegisterPage(),
          fromRight: true,
        );

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            email: args['email'],
          ),
        );

      case emailVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EmailVerificationPage(
            email: args['email'],
          ),
        );

      case completeProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CompleteProfilePage(
            email: args?['email'] ?? '',
            name: args?['name'],
            providerId: args?['providerId'] ?? 'google',
            accessToken: args?['accessToken'] ?? '',
            requiresRegistration: args?['requiresRegistration'] ?? true,
          ),
        );

      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case menu:
        return MaterialPageRoute(builder: (_) => const MenuPage());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case subscriptions:
        return MaterialPageRoute(builder: (_) => const SubscriptionsPage());

      case certificates:
        return MaterialPageRoute(builder: (_) => const CertificatesPage());

      case transactions:
        return MaterialPageRoute(builder: (_) => const TransactionsPage());

      case courses:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AllCoursesPage(
            categoryId: args?['categoryId'],
            specialtyId: args?['specialtyId'],
            title: args?['title'],
          ),
        );

      case lesson:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => LessonPlayerPage(
            lessonId: args['lessonId'],
            lesson: args['lesson'],
          ),
        );

      case about:
        return MaterialPageRoute(builder: (_) => const AboutPage());

      case reelsFeed:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ReelsBloc>()..add(const LoadReelsFeedEvent(perPage: 10)),
            child: ReelsFeedPage(
              initialIndex: args?['initialIndex'] ?? 0,
            ),
          ),
        );

      case contentPreferences:
        return MaterialPageRoute(builder: (_) => const ContentPreferencesPage());

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'الصفحة غير موجودة',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('No route defined for ${settings.name}'),
                ],
              ),
            ),
          ),
        );
    }
  }

  static PageRoute _buildAuthPageRoute(
    Widget child, {
    required bool fromRight,
  }) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        if (!Responsive.isTablet(ctx)) {
          return child;
        }

        final beginOffset = Offset(fromRight ? 1.0 : -1.0, 0);
        final endOffset = Offset.zero;
        final tween = Tween(begin: beginOffset, end: endOffset)
            .chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}


