part of 'auth_cubit.dart';

abstract class AuthState {
  const AuthState();
}

/// Initial / idle state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// API call in progress — show loading indicator
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Login or user-register succeeded — tokens + user available
class AuthSuccess extends AuthState {
  final UserModel user;
  final AuthTokens? tokens; // null for pending-approval roles
  final String message;

  const AuthSuccess({
    required this.user,
    this.tokens,
    this.message = '',
  });
}

/// Doctor / Hospital registered — awaiting admin approval
class AuthPendingApproval extends AuthState {
  final String message;
  final String role;

  const AuthPendingApproval({
    required this.message,
    required this.role,
  });
}

/// Any auth operation failed
class AuthFailure extends AuthState {
  final String message;
  final Map<String, dynamic>? fieldErrors; // backend field-level errors

  const AuthFailure(
    this.message, {
    this.fieldErrors,
  });
}

/// Password changed successfully
class PasswordChanged extends AuthState {
  final String message;
  const PasswordChanged(this.message);
}

/// User logged out
class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
