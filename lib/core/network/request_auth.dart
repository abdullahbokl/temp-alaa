import '../constants/api_constants.dart';

enum AuthRequirement { public, optional, protected }

class RequestAuthMeta {
  static const String authRequirementKey = 'auth_requirement';
  static const String authAttachedKey = 'auth_attached';
}

class RequestAuthPolicyResolver {
  const RequestAuthPolicyResolver._();

  static AuthRequirement resolve(String path) {
    final normalized = _normalize(path);

    if (_publicPaths.contains(normalized)) {
      return AuthRequirement.public;
    }

    if (_isOptionalCoursePath(normalized)) {
      return AuthRequirement.optional;
    }

    if (_protectedExactPaths.contains(normalized)) {
      return AuthRequirement.protected;
    }

    if (_protectedPrefixes.any(normalized.startsWith)) {
      return AuthRequirement.protected;
    }

    return AuthRequirement.optional;
  }

  static String _normalize(String path) {
    final cleanPath = path.split('?').first.trim();
    return cleanPath.endsWith('/')
        ? cleanPath.substring(0, cleanPath.length - 1)
        : cleanPath;
  }

  static bool _isOptionalCoursePath(String path) {
    if (path == ApiConstants.courses) return true;
    return RegExp(r'^courses/\d+$').hasMatch(path);
  }

  static final Set<String> _publicPaths = {
    ApiConstants.homeApi,
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.forgotPassword,
    ApiConstants.resetPassword,
    ApiConstants.googleAuth,
    ApiConstants.googleCallback,
    ApiConstants.mobileOAuthLogin,
  };

  static final Set<String> _protectedExactPaths = {
    ApiConstants.myCourses,
    ApiConstants.loggedInUser,
    ApiConstants.profile,
    ApiConstants.updateProfile,
    ApiConstants.logout,
    ApiConstants.sendEmailOtp,
    ApiConstants.verifyEmailOtp,
    ApiConstants.checkEmailVerification,
    ApiConstants.changePassword,
    ApiConstants.generateCertificate,
    ApiConstants.ownedCertificates,
    ApiConstants.processPayment,
    ApiConstants.myTransactions,
    ApiConstants.validateIapReceipt,
  };

  static final List<String> _protectedPrefixes = [
    'subscriptions',
    'certificates',
    'payments',
    'transactions',
    'reels/',
    'reel-categories/',
    'auth/',
    'user/',
  ];
}
