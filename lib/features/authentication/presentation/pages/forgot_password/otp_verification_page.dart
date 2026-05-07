import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../widgets/passwordField.dart';
import '../../widgets/primary_button.dart';
import '../login/widgets/login_background.dart';

class OtpVerificationPage extends StatelessWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: _OtpVerificationPageContent(email: email),
    );
  }
}

class _OtpVerificationPageContent extends StatefulWidget {
  final String email;

  const _OtpVerificationPageContent({required this.email});

  @override
  State<_OtpVerificationPageContent> createState() =>
      _OtpVerificationPageContentState();
}

class _OtpVerificationPageContentState
    extends State<_OtpVerificationPageContent> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _handleOtpInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != _passwordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  void _handleResetPassword() {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إدخال رمز التحقق المكون من 6 أرقام'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        ResetPasswordEvent(
          email: widget.email,
          otp: _otp,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        ),
      );
    }
  }

  void _resendOtp() {
    if (_canResend) {
      context.read<AuthBloc>().add(ForgotPasswordEvent(email: widget.email));
      _startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: Responsive.iconSize(context, 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const LoginBackground(),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else if (state is PasswordResetSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تغيير كلمة المرور بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              } else if (state is ForgotPasswordSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم إعادة إرسال رمز التحقق'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: SafeArea(
              child: SingleChildScrollView(
                padding: Responsive.padding(context, all: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: Responsive.spacing(context, 20)),

                      Text(
                        'التحقق من البريد',
                        style: AppTextStyles.displayMedium.copyWith(
                          fontSize: Responsive.fontSize(context, 28),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: Responsive.spacing(context, 12)),

                      Text(
                        'أدخل رمز التحقق المرسل إلى\n${widget.email}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.fontSize(context, 14),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: Responsive.spacing(context, 32)),

                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: Responsive.width(context, 48),
                              height: Responsive.height(context, 56),
                              child: TextFormField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 24),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: AppColors.inputBackground,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.radius(context, 12),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.greyLight,
                                      width: Responsive.width(context, 1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.radius(context, 12),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: Responsive.width(context, 2),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.radius(context, 12),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.greyLight,
                                      width: Responsive.width(context, 1),
                                    ),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) =>
                                    _handleOtpInput(value, index),
                              ),
                            );
                          }),
                        ),
                      ),

                      SizedBox(height: Responsive.spacing(context, 16)),

                      Center(
                        child: _canResend
                            ? TextButton(
                          onPressed: _resendOtp,
                          child: Text(
                            'إعادة إرسال الرمز',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              fontSize: Responsive.fontSize(context, 14),
                            ),
                          ),
                        )
                            : Text(
                          'إعادة الإرسال بعد $_resendSeconds ثانية',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.spacing(context, 32)),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.greyLight,
                              thickness: Responsive.width(context, 1),
                            ),
                          ),
                          Padding(
                            padding: Responsive.padding(context, horizontal: 16),
                            child: Text(
                              'كلمة المرور الجديدة',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'Cairo',
                                fontSize: Responsive.fontSize(context, 14),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.greyLight,
                              thickness: Responsive.width(context, 1),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.spacing(context, 24)),

                      PasswordField(
                        controller: _passwordController,
                        obscure: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        hintText: 'كلمة المرور الجديدة',
                        validator: _validatePassword,
                      ),

                      SizedBox(height: Responsive.spacing(context, 16)),

                      PasswordField(
                        controller: _confirmPasswordController,
                        obscure: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                        hintText: 'تأكيد كلمة المرور',
                        validator: _validateConfirmPassword,
                      ),

                      SizedBox(height: Responsive.spacing(context, 32)),

                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return PrimaryButton(
                            text: 'تغيير كلمة المرور',
                            onPressed: isLoading ? null : _handleResetPassword,
                            isLoading: isLoading,
                          );
                        },
                      ),
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
}
