import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  AuthCubit(this._repository, {TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        super(const AuthInitial());

  // ─── Login ─────────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.login(
        email: email,
        password: password,
      );
      await _tokenStorage.saveTokens(result.tokens!);
      await _tokenStorage.saveUser(result.user);
      emit(AuthSuccess(
        user: result.user,
        tokens: result.tokens,
        message: 'Login successful',
      ));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message, fieldErrors: e.errors));
    } catch (e) {
      log('error :: $e');
      emit(const AuthFailure(
        'Unable to connect. Please check your internet connection.',
      ));
    }
  }

  // ─── Register Patient ──────────────────────────────────────────────────────

  Future<void> registerUser({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.registerUser(
        email: email,
        fullName: fullName,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
      );
      await _tokenStorage.saveTokens(result.tokens!);
      await _tokenStorage.saveUser(result.user);
      emit(AuthSuccess(
        user: result.user,
        tokens: result.tokens,
        message: 'Account created successfully!',
      ));
    } on ApiException catch (e) {
      log(e.toString());
      emit(AuthFailure(e.message, fieldErrors: e.errors));
    } catch (e) {
      log(e.toString());

      emit(const AuthFailure(
        'Unable to connect. Please check your internet connection.',
      ));
    }
  }

  // ─── Register Doctor ───────────────────────────────────────────────────────

  Future<void> registerDoctor({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    required DoctorProfile doctorProfile,
  }) async {
    emit(const AuthLoading());
    try {
      await _repository.registerDoctor(
        email: email,
        fullName: fullName,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        doctorProfile: doctorProfile,
      );
      emit(const AuthPendingApproval(
        message:
            'Registration submitted! Your account is pending admin approval. You will be notified once approved.',
        role: UserRole.doctor,
      ));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message, fieldErrors: e.errors));
    } catch (e) {
      log(e.toString());

      emit(const AuthFailure(
        'Unable to connect. Please check your internet connection.',
      ));
    }
  }

  // ─── Register Hospital ─────────────────────────────────────────────────────

  Future<void> registerHospital({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    required HospitalProfile hospitalProfile,
  }) async {
    emit(const AuthLoading());
    try {
      await _repository.registerHospital(
        email: email,
        fullName: fullName,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        hospitalProfile: hospitalProfile,
      );
      emit(const AuthPendingApproval(
        message:
            'Hospital registration submitted! Awaiting admin approval and verification.',
        role: UserRole.hospital,
      ));
    } on ApiException catch (e) {
      log(e.toString());

      emit(AuthFailure(e.message, fieldErrors: e.errors));
    } catch (e) {
      log(e.toString());

      emit(const AuthFailure(
        'Unable to connect. Please check your internet connection.',
      ));
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      final access = await _tokenStorage.getAccessToken();
      final refresh = await _tokenStorage.getRefreshToken();
      if (access != null && refresh != null) {
        await _repository.logout(
          accessToken: access,
          refreshToken: refresh,
        );
      }
    } catch (e) {
      log(e.toString());

      // Even if API call fails, still clear local tokens
    } finally {
      await _tokenStorage.clearAll();
      emit(const AuthLoggedOut());
    }
  }

  // ─── Change Password ───────────────────────────────────────────────────────

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    emit(const AuthLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(const AuthFailure('Session expired. Please log in again.'));
        return;
      }
      await _repository.changePassword(
        accessToken: token,
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      emit(const PasswordChanged('Password changed successfully.'));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message, fieldErrors: e.errors));
    } catch (e) {
      log(e.toString());

      emit(const AuthFailure(
        'Unable to connect. Please check your internet connection.',
      ));
    }
  }

  // ─── Check Existing Session ────────────────────────────────────────────────

Future<void> checkSession() async {
  emit(const AuthLoading());

  try {
    final user = await _tokenStorage.getUser();
    final token = await _tokenStorage.getAccessToken();

    if (user != null && token != null) {
      emit(AuthSuccess(user: user, message: 'Session restored'));
    } else {
      emit(const AuthUnauthenticated());
    }
  } catch (e) {
    log(e.toString());
    emit(const AuthUnauthenticated());
  }
}

  // ─── Reset ─────────────────────────────────────────────────────────────────

  void reset() => emit(const AuthInitial());
}
