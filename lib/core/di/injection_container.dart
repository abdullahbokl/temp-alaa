import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/authentication/data/datasources/auth_local_datasource.dart';
import '../../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/login_usecase.dart';
import '../../features/authentication/domain/usecases/register_usecase.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/certificates/data/datasources/certificate_remote_datasource.dart';
import '../../features/certificates/data/repositories/certificate_repository_impl.dart';
import '../../features/certificates/domain/repositories/certificate_repository.dart';
import '../../features/certificates/domain/usecases/generate_certificate_usecase.dart';
import '../../features/certificates/domain/usecases/get_certificate_by_id_usecase.dart';
import '../../features/certificates/domain/usecases/get_owned_certificates_usecase.dart';
import '../../features/certificates/presentation/bloc/certificate_bloc.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_data_usecase.dart';
import '../../features/home/domain/usecases/get_latest_courses_usecase.dart';
import '../../features/home/domain/usecases/get_free_courses_usecase.dart';
import '../../features/home/domain/usecases/get_popular_courses_usecase.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import '../../features/subscriptions/data/repositories/subscription_repository_impl.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../../features/subscriptions/domain/usecases/create_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscription_by_id_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import '../../features/subscriptions/domain/usecases/update_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/verify_iap_receipt_usecase.dart';
import '../../features/subscriptions/presentation/bloc/subscription_bloc.dart';
import '../../features/courses/data/datasources/course_remote_datasource.dart';
import '../../features/courses/data/repositories/course_repository_impl.dart';
import '../../features/courses/domain/repositories/course_repository.dart';
import '../../features/courses/domain/usecases/get_courses_usecase.dart';
import '../../features/courses/domain/usecases/get_course_by_id_usecase.dart';
import '../../features/courses/domain/usecases/get_my_courses_usecase.dart';
import '../../features/courses/presentation/bloc/courses_bloc.dart';
import '../../features/lessons/data/datasources/lesson_remote_datasource.dart';
import '../../features/lessons/data/repositories/lesson_repository_impl.dart';
import '../../features/lessons/domain/repositories/lesson_repository.dart';
import '../../features/lessons/domain/usecases/get_lesson_by_id_usecase.dart';
import '../../features/lessons/domain/usecases/mark_lesson_viewed_usecase.dart';
import '../../features/lessons/presentation/bloc/lesson_bloc.dart';
import '../../features/chapters/data/datasources/chapter_remote_datasource.dart';
import '../../features/chapters/data/repositories/chapter_repository_impl.dart';
import '../../features/chapters/domain/repositories/chapter_repository.dart';
import '../../features/chapters/domain/usecases/get_chapter_by_id_usecase.dart';
import '../../features/chapters/presentation/bloc/chapter_bloc.dart';
import '../../features/reels/data/datasources/reels_remote_datasource.dart';
import '../../features/reels/data/repositories/reels_repository_impl.dart';
import '../../features/reels/domain/repositories/reels_repository.dart';
import '../../features/reels/domain/usecases/get_reels_feed_usecase.dart';
import '../../features/reels/domain/usecases/record_reel_view_usecase.dart';
import '../../features/reels/domain/usecases/toggle_reel_like_usecase.dart';
import '../../features/reels/domain/usecases/get_reel_categories_usecase.dart';
import '../../features/reels/domain/usecases/get_user_reels_usecase.dart';
import '../../features/reels/domain/usecases/get_user_liked_reels_usecase.dart';
import '../../features/reels/presentation/bloc/reels_bloc.dart';
import '../../features/banners/data/datasources/banners_remote_datasource.dart';
import '../../features/banners/data/repositories/banners_repository_impl.dart';
import '../../features/banners/domain/repositories/banners_repository.dart';
import '../../features/banners/domain/usecases/get_site_banners_usecase.dart';
import '../../features/banners/domain/usecases/record_banner_click_usecase.dart';
import '../../features/transactions/data/datasources/transactions_remote_datasource.dart';
import '../../features/transactions/data/repositories/transactions_repository_impl.dart';
import '../../features/transactions/domain/repositories/transactions_repository.dart';
import '../../features/transactions/domain/usecases/get_my_transactions_usecase.dart';
import '../../features/transactions/presentation/bloc/transactions_bloc.dart';
import '../network/dio_client.dart';
import '../storage/hive_service.dart';
import '../storage/secure_storage_service.dart';
import '../services/realtime_update_service.dart';
import '../events/global_event_bus.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton(() => secureStorage);

  sl.registerLazySingleton(() => SecureStorageService(sl()));
  sl.registerLazySingleton(() => HiveService());
  sl.registerLazySingleton(() => DioClient(sl()));
  sl.registerLazySingleton(() => RealtimeUpdateService());
  sl.registerLazySingleton(() => GlobalEventBus());

  _initAuth();
  _initCertificates();
  _initHome();
  _initSubscriptions();
  _initCourses();
  _initLessons();
  _initChapters();
  _initReels();
  _initBanners();
  _initTransactions();
}

void _initAuth() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(
      hiveService: sl(),
      secureStorage: sl(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      sharedPreferences: sl(),
      secureStorage: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  sl.registerFactory(
        () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      authRepository: sl(),
      globalEventBus: sl(),
    ),
  );
}

void _initCertificates() {
  sl.registerLazySingleton<CertificateRemoteDataSource>(
        () => CertificateRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<CertificateRepository>(
        () => CertificateRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GenerateCertificateUseCase(sl()));
  sl.registerLazySingleton(() => GetOwnedCertificatesUseCase(sl()));
  sl.registerLazySingleton(() => GetCertificateByIdUseCase(sl()));

  sl.registerFactory(
        () => CertificateBloc(
      generateCertificateUseCase: sl(),
      getOwnedCertificatesUseCase: sl(),
      getCertificateByIdUseCase: sl(),
    ),
  );
}

void _initHome() {
  sl.registerLazySingleton<HomeRemoteDataSource>(
        () => HomeRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<HomeRepository>(
        () => HomeRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetHomeDataUseCase(sl()));
  sl.registerLazySingleton(() => GetLatestCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetFreeCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetPopularCoursesUseCase(sl()));

  sl.registerFactory(
    () => HomeBloc(
      getHomeDataUseCase: sl(),
      getLatestCoursesUseCase: sl(),
      getFreeCoursesUseCase: sl(),
      getPopularCoursesUseCase: sl(),
    ),
  );
}

void _initSubscriptions() {
  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
        () => SubscriptionRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<SubscriptionRepository>(
        () => SubscriptionRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetSubscriptionsUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => VerifyIapReceiptUseCase(sl()));

  sl.registerFactory(
        () => SubscriptionBloc(
      getSubscriptionsUseCase: sl(),
      getSubscriptionByIdUseCase: sl(),
      createSubscriptionUseCase: sl(),
      updateSubscriptionUseCase: sl(),
      subscriptionRepository: sl(),
      verifyIapReceiptUseCase: sl(),
      globalEventBus: sl(),
    ),
  );
}

void _initCourses() {
  sl.registerLazySingleton<CourseRemoteDataSource>(
        () => CourseRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<CourseRepository>(
        () => CourseRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetCourseByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetMyCoursesUseCase(sl()));

  sl.registerFactory(
        () => CoursesBloc(
      getCoursesUseCase: sl(),
      getCourseByIdUseCase: sl(),
      getMyCoursesUseCase: sl(),
      globalEventBus: sl(),
    ),
  );
}

void _initLessons() {
  sl.registerLazySingleton<LessonRemoteDataSource>(
        () => LessonRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<LessonRepository>(
        () => LessonRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetLessonByIdUseCase(sl()));
  sl.registerLazySingleton(() => MarkLessonViewedUseCase(sl()));

  sl.registerFactory(
        () => LessonBloc(
      getLessonByIdUseCase: sl(),
      markLessonViewedUseCase: sl(),
    ),
  );
}

void _initChapters() {
  sl.registerLazySingleton<ChapterRemoteDataSource>(
        () => ChapterRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ChapterRepository>(
        () => ChapterRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetChapterByIdUseCase(sl()));

  sl.registerFactory(
        () => ChapterBloc(
      getChapterByIdUseCase: sl(),
    ),
  );
}

void _initReels() {
  sl.registerLazySingleton<ReelsRemoteDataSource>(
        () => ReelsRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ReelsRepository>(
        () => ReelsRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetReelsFeedUseCase(sl()));
  sl.registerLazySingleton(() => RecordReelViewUseCase(sl()));
  sl.registerLazySingleton(() => ToggleReelLikeUseCase(sl()));
  sl.registerLazySingleton(() => GetReelCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetUserReelsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserLikedReelsUseCase(sl()));

  sl.registerFactory(
        () => ReelsBloc(
      getReelsFeedUseCase: sl(),
      recordReelViewUseCase: sl(),
      toggleReelLikeUseCase: sl(),
      getReelCategoriesUseCase: sl(),
      getUserReelsUseCase: sl(),
      getUserLikedReelsUseCase: sl(),
      globalEventBus: sl(),
    ),
  );
}

void _initBanners() {
  sl.registerLazySingleton<BannersRemoteDataSource>(
        () => BannersRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<BannersRepository>(
        () => BannersRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => GetSiteBannersUseCase(sl()));
  sl.registerLazySingleton(() => RecordBannerClickUseCase(sl()));
}

void _initTransactions() {
  sl.registerLazySingleton<TransactionsRemoteDataSource>(
        () => TransactionsRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<TransactionsRepository>(
        () => TransactionsRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMyTransactionsUseCase(sl()));

  sl.registerFactory(
        () => TransactionsBloc(
      getMyTransactionsUseCase: sl(),
    ),
  );
}


