import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learnify_lms/core/theme/app_text_styles.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../home/domain/entities/course.dart';
import '../../../home/presentation/pages/course_details_page.dart';
import '../bloc/courses_bloc.dart';
import '../bloc/courses_event.dart';
import '../bloc/courses_state.dart';
import '../widgets/course_circle_item.dart';

class AllCoursesPage extends StatelessWidget {
  final int? categoryId;
  final int? specialtyId;
  final String? title;
  final bool isMyCourses;

  const AllCoursesPage({
    super.key,
    this.categoryId,
    this.specialtyId,
    this.title,
    this.isMyCourses = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<CoursesBloc>();
        if (isMyCourses) {
          bloc.add(const LoadMyCoursesEvent());
        } else {
          bloc.add(LoadCoursesEvent(categoryId: categoryId, specialtyId: specialtyId));
        }
        return bloc;
      },
      child: _AllCoursesPageContent(
        title: title ?? (isMyCourses ? 'كورساتي' : 'كل الكورسات'),
        isMyCourses: isMyCourses,
      ),
    );
  }
}

class _AllCoursesPageContent extends StatelessWidget {
  final String title;
  final bool isMyCourses;

  const _AllCoursesPageContent({
    required this.title,
    required this.isMyCourses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: title),
      body: Stack(
        children: [
          const CustomBackground(),
          BlocConsumer<CoursesBloc, CoursesState>(
            listener: (context, state) {
              if (state.errorMessage != null && state.items.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              if (state.isInitialLoading && state.items.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (state.items.isEmpty && state.errorMessage != null) {
                return _buildErrorState(context, state.errorMessage!);
              }

              if (state.items.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildCoursesList(context, state);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context, CoursesState state) {
    final media = MediaQuery.of(context);
    final isPortrait = media.orientation == Orientation.portrait;
    final isTabletPortrait = isPortrait && media.size.shortestSide >= 600;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            !state.isLoadingMore &&
            state.hasMore) {
          context.read<CoursesBloc>().add(const LoadMoreCoursesEvent());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          if (isMyCourses) {
            context.read<CoursesBloc>().add(const LoadMyCoursesEvent(refresh: true));
          } else {
            context.read<CoursesBloc>().add(const LoadCoursesEvent(refresh: true));
          }
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: Responsive.padding(context, all: 16),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = Responsive.isTablet(context);
                  final crossAxisCount = isTablet ? (isTabletPortrait ? 2 : 3) : 2;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: Responsive.width(context, 8),
                      mainAxisSpacing: Responsive.height(context, 12),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = state.items[index];
                        return CourseCircleItem(
                          course: course,
                          onTap: () => _navigateToCourseDetails(context, course),
                        );
                      },
                      childCount: state.items.length,
                    ),
                  );
                },
              ),
            ),
            if (state.isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: Responsive.padding(context, all: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: Responsive.width(context, 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: Responsive.iconSize(context, 80), color: Colors.grey[400]),
          SizedBox(height: Responsive.spacing(context, 16)),
          Text(
            'لا توجد كورسات متاحة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: Responsive.fontSize(context, 18),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final isAuthError = message.contains('يجب تسجيل الدخول أولاً') ||
        message.contains('تسجيل الدخول') ||
        message.toLowerCase().contains('unauthorized');

    if (!isAuthError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: Responsive.iconSize(context, 80), color: Colors.red[400]),
            SizedBox(height: Responsive.spacing(context, 16)),
            Text('حدث خطأ', style: TextStyle(fontFamily: 'Cairo', fontSize: Responsive.fontSize(context, 18))),
            SizedBox(height: Responsive.spacing(context, 8)),
            Padding(
              padding: Responsive.padding(context, horizontal: 32),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: Responsive.padding(context, horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.width(context, 32)),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.lock_outline, size: Responsive.iconSize(context, 80), color: AppColors.primary),
              ),
              SizedBox(height: Responsive.spacing(context, 24)),
              Text(
                'تسجيل الدخول مطلوب',
                style: AppTextStyles.displayMedium.copyWith(fontSize: Responsive.fontSize(context, 24)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.spacing(context, 12)),
              Text(
                'للوصول إلى الكورسات، يرجى تسجيل الدخول أو إنشاء حساب جديد',
                style: AppTextStyles.bodyLarge.copyWith(fontSize: Responsive.fontSize(context, 16), height: 1.4),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.spacing(context, 28)),
              SizedBox(
                width: double.infinity,
                height: Responsive.height(context, 56),
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRouter.login,
                      arguments: {'returnTo': 'courses'},
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCourseDetails(BuildContext context, Course course) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsPage(course: course)));
  }
}
