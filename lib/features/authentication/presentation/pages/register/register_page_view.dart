import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/responsive.dart';
import 'package:learnify_lms/features/authentication/presentation/pages/register/widgets/have_account_row.dart';
import 'package:learnify_lms/features/authentication/presentation/widgets/name_field.dart';
import 'package:learnify_lms/features/authentication/presentation/widgets/phone_field.dart';
import 'package:learnify_lms/features/authentication/presentation/pages/register/widgets/register_header.dart';
import 'package:learnify_lms/features/authentication/presentation/pages/login/widgets/login_background.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/age_specialty_helper.dart';

import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../widgets/emailField.dart';
import '../../widgets/passwordField.dart';
import '../../widgets/birthday_field.dart';
import '../../widgets/custom_divider_with_text.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_login_buttons.dart';

class RegisterPageView extends StatefulWidget {
  const RegisterPageView({super.key});

  @override
  State<RegisterPageView> createState() => RegisterPageViewState();
}

class RegisterPageViewState extends State<RegisterPageView> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final dayController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();

  bool obscurePassword = true;
  String? countryCode;
  String selectedRole = 'student';
  String selectedGender = 'male';
  String selectedReligion = 'muslim';

  int? calculatedAge;
  int? calculatedSpecialtyId;
  String? specialtyName;

  @override
  void initState() {
    super.initState();
    dayController.addListener(_updateAgeAndSpecialty);
    monthController.addListener(_updateAgeAndSpecialty);
    yearController.addListener(_updateAgeAndSpecialty);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  void _updateAgeAndSpecialty() {
    final birthday = _getBirthdayString();
    if (birthday != null) {
      try {
        final parts = birthday.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final birthDate = DateTime(year, month, day);
        final age = AgeSpecialtyHelper.calculateAge(birthDate);
        final specialtyId = AgeSpecialtyHelper.getSpecialtyIdFromAge(age);
        final name = AgeSpecialtyHelper.getSpecialtyNameAr(age);

        setState(() {
          calculatedAge = age;
          calculatedSpecialtyId = specialtyId;
          specialtyName = name;
        });
      } catch (e) {
        setState(() {
          calculatedAge = null;
          calculatedSpecialtyId = null;
          specialtyName = null;
        });
      }
    } else {
      setState(() {
        calculatedAge = null;
        calculatedSpecialtyId = null;
        specialtyName = null;
      });
    }
  }

  String? _getBirthdayString() {
    if (dayController.text.isEmpty ||
        monthController.text.isEmpty ||
        yearController.text.isEmpty) {
      return null;
    }

    final day = dayController.text.padLeft(2, '0');
    final month = monthController.text.padLeft(2, '0');
    final year = yearController.text;

    if (year.length != 4) return null;

    return '$year-$month-$day';
  }

  void onRegisterPressed() {
    if (formKey.currentState!.validate()) {
      if (calculatedAge == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى إدخال تاريخ الميلاد'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!AgeSpecialtyHelper.isValidAge(calculatedAge!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AgeSpecialtyHelper.getAgeValidationMessage(calculatedAge!) ??
                  'العمر غير صالح للتسجيل',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(
            RegisterEvent(
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              password: passwordController.text,
              passwordConfirmation: passwordController.text,
              role: selectedRole,
              phone: countryCode != null
                  ? '$countryCode${phoneController.text.trim()}'
                  : phoneController.text.trim(),
              specialtyId: calculatedSpecialtyId!,
              gender: selectedGender,
              religion: selectedReligion,
              birthday: _getBirthdayString(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildPhoneLayout(context);
    }
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          const LoginBackground(),
          BlocListener<AuthBloc, AuthState>(
            listener: authListener,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: Responsive.padding(context, horizontal: 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      SizedBox(height: Responsive.spacing(context, 50)),
                      const RegisterHeader(),
                      SizedBox(height: Responsive.spacing(context, 22)),
                      NameField(controller: nameController),
                      SizedBox(height: Responsive.spacing(context, 16)),
                      BirthdayField(
                        dayController: dayController,
                        monthController: monthController,
                        yearController: yearController,
                      ),
                      if (calculatedAge != null) ...[
                        SizedBox(height: Responsive.spacing(context, 8)),
                        _buildAgeSpecialtyInfo(context),
                      ],
                      SizedBox(height: Responsive.spacing(context, 16)),
                      PhoneField(
                        controller: phoneController,
                        countryCode: countryCode,
                        onCountryChanged: (v) =>
                            setState(() => countryCode = v),
                      ),
                      SizedBox(height: Responsive.spacing(context, 16)),
                      EmailField(controller: emailController),
                      SizedBox(height: Responsive.spacing(context, 16)),
                      PasswordField(
                        controller: passwordController,
                        obscure: obscurePassword,
                        onToggleVisibility: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                      SizedBox(height: Responsive.spacing(context, 28)),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return PrimaryButton(
                            text: 'تسجيل الحساب',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : onRegisterPressed,
                          );
                        },
                      ),
                      SizedBox(height: Responsive.spacing(context, 12)),
                      const HaveAccountRow(),
                      SizedBox(height: Responsive.spacing(context, 16)),
                      const CustomDividerWithText(text: "أو التسجيل بواسطة"),
                      SizedBox(height: Responsive.spacing(context, 20)),
                      const SocialLoginButtons(),
                      SizedBox(height: Responsive.spacing(context, 30)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final isPortrait = Responsive.isPortrait(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        resizeToAvoidBottomInset: false,
        body: BlocListener<AuthBloc, AuthState>(
          listener: authListener,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isPortrait ? 600 : 1000,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOpacity10,
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: isPortrait
                        ? _buildPortraitTabletLayout(context)
                        : _buildLandscapeTabletLayout(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                32,
                32,
                32,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'إنشاء حساب',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.fontSize(context, 26),
                              ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'املأ البيانات التالية لإنشاء حساب لطفلك وبدء رحلة التعلم.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.fontSize(context, 15),
                            height: 1.4,
                          ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: NameField(controller: nameController),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: BirthdayField(
                        dayController: dayController,
                        monthController: monthController,
                        yearController: yearController,
                      ),
                    ),
                    if (calculatedAge != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _buildAgeSpecialtyInfo(context),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: PhoneField(
                        controller: phoneController,
                        countryCode: countryCode,
                        onCountryChanged: (v) =>
                            setState(() => countryCode = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: EmailField(controller: emailController),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: PasswordField(
                        controller: passwordController,
                        obscure: obscurePassword,
                        onToggleVisibility: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return PrimaryButton(
                            text: 'تسجيل الحساب',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : onRegisterPressed,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: double.infinity,
                      child: HaveAccountRow(),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: double.infinity,
                      child: CustomDividerWithText(
                        text: "أو التسجيل بواسطة",
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: const SocialLoginButtons()),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: MediaQuery(
            data: MediaQuery.of(context).removeViewInsets(removeBottom: true),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: constraints.maxHeight,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryCard,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(120),
                        bottomLeft: Radius.circular(120),
                        bottomRight: Radius.circular(28),
                        topRight: Radius.circular(28)),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 40,
                          right: 20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 80,
                          left: 30,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.15),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const RegisterHeader(),
                                SizedBox(
                                    height: Responsive.spacing(context, 24)),
                                Icon(
                                  Icons.rocket_launch_outlined,
                                  size: Responsive.iconSize(context, 56),
                                  color: AppColors.primary,
                                ),
                                SizedBox(
                                    height: Responsive.spacing(context, 20)),
                                SizedBox(
                                    height: Responsive.spacing(context, 10)),
                                Text(
                                  'أنشئ حسابك وابدأ رحلة التعلّم المميزة مع ليرنيفاى.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize:
                                            Responsive.fontSize(context, 15),
                                        height: 1.4,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: const BoxDecoration(
              color: AppColors.primaryCard,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 30,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const RegisterHeader(),
                      SizedBox(height: Responsive.spacing(context, 20)),
                      Icon(
                        Icons.rocket_launch_outlined,
                        size: Responsive.iconSize(context, 50),
                        color: AppColors.primary,
                      ),
                      SizedBox(height: Responsive.spacing(context, 16)),
                      Text(
                        'أنشئ حسابك وابدأ رحلة التعلّم المميزة مع ليرنيفاى.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: Responsive.fontSize(context, 15),
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                32,
                32,
                32,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'إنشاء حساب',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.fontSize(context, 26),
                              ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'املأ البيانات التالية لإنشاء حساب لطفلك وبدء رحلة التعلم.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.fontSize(context, 15),
                            height: 1.4,
                          ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: NameField(controller: nameController),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: BirthdayField(
                        dayController: dayController,
                        monthController: monthController,
                        yearController: yearController,
                      ),
                    ),
                    if (calculatedAge != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _buildAgeSpecialtyInfo(context),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: PhoneField(
                        controller: phoneController,
                        countryCode: countryCode,
                        onCountryChanged: (v) =>
                            setState(() => countryCode = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: EmailField(controller: emailController),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: PasswordField(
                        controller: passwordController,
                        obscure: obscurePassword,
                        onToggleVisibility: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return PrimaryButton(
                            text: 'تسجيل الحساب',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : onRegisterPressed,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: double.infinity,
                      child: HaveAccountRow(),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: double.infinity,
                      child: CustomDividerWithText(
                        text: "أو التسجيل بواسطة",
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: const SocialLoginButtons()),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeSpecialtyInfo(BuildContext context) {
    final isValidAge = AgeSpecialtyHelper.isValidAge(calculatedAge!);

    return Container(
      padding: Responsive.padding(context, horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isValidAge
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
        border: Border.all(
          color: isValidAge ? AppColors.success : AppColors.error,
          width: Responsive.width(context, 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValidAge ? Icons.check_circle : Icons.error,
            color: isValidAge ? AppColors.success : AppColors.error,
            size: Responsive.iconSize(context, 20),
          ),
          SizedBox(width: Responsive.width(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'العمر: $calculatedAge سنة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: isValidAge ? AppColors.success : AppColors.error,
                  ),
                ),
                if (specialtyName != null)
                  Text(
                    'الفئة العمرية: $specialtyName',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: Responsive.fontSize(context, 12),
                      color: isValidAge
                          ? AppColors.success.withOpacity(0.8)
                          : AppColors.error.withOpacity(0.8),
                    ),
                  )
                else if (!isValidAge)
                  Text(
                    AgeSpecialtyHelper.getAgeValidationMessage(
                            calculatedAge!) ??
                        'العمر غير صالح',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: Responsive.fontSize(context, 12),
                      color: AppColors.error.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void authListener(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is AuthAuthenticated) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final returnTo = args?['returnTo'] as String?;

      if (returnTo == 'profile' ||
          returnTo == 'subscriptions' ||
          returnTo == 'certificates') {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacementNamed('/content-preferences');
      }
    }
  }
}
