import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/user_model.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isPendingPhoneVerification = false,
    this.pendingPhone = '+237 6 70 12 34 56',
    this.isLoading = false,
    this.errorMessage,
  });

  final User? user;
  final bool isAuthenticated;
  final bool isPendingPhoneVerification;
  final String pendingPhone;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isPendingPhoneVerification,
    String? pendingPhone,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPendingPhoneVerification:
          isPendingPhoneVerification ?? this.isPendingPhoneVerification,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Manages authentication, registration, phone OTP verification, and profile state.
class AuthController extends StateNotifier<AuthState> {
  AuthController({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage,
      super(
        const AuthState(
          user: User(
            id: 'usr_cam_001',
            fullName: 'Ngwa Emmanuel',
            email: 'emmanuel.ngwa@njangiva.cm',
            phoneNumber: '+237 6 70 12 34 56',
            isPhoneVerified: true,
          ),
          isAuthenticated: false,
        ),
      );

  final TokenStorage _tokenStorage;

  /// Registers a new user account and transitions to Phone Verification (Screen E).
  Future<bool> registerAccount({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final newUser = User(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      isPhoneVerified: false,
    );

    state = state.copyWith(
      user: newUser,
      isAuthenticated: false,
      isPendingPhoneVerification: true,
      pendingPhone: phoneNumber.trim(),
      isLoading: false,
    );
    return true;
  }

  /// Mock OTP verification service for development.
  /// Accepts any valid 6-digit numeric code (e.g., `123456`) and issues a session token.
  Future<bool> verifyPhoneOtp(String otpCode) async {
    final cleaned = otpCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(cleaned)) {
      state = state.copyWith(
        errorMessage: 'Please enter all 6 digits of the verification code.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (cleaned == '000000') {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid verification code. Try 123456 in dev mode.',
      );
      return false;
    }

    final currentUser =
        state.user ??
        User(
          id: 'usr_cam_001',
          fullName: 'Ngwa Emmanuel',
          email: 'emmanuel.ngwa@njangisave.cm',
          phoneNumber: state.pendingPhone,
          isPhoneVerified: true,
        );

    final verifiedUser = currentUser.copyWith(isPhoneVerified: true);

    await _tokenStorage.saveTokens(
      AuthTokenPair(
        accessToken: 'njangi_jwt_${verifiedUser.id}',
        refreshToken: 'njangi_refresh_${verifiedUser.id}',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 24)),
      ),
    );

    state = state.copyWith(
      user: verifiedUser,
      isAuthenticated: true,
      isPendingPhoneVerification: false,
      isLoading: false,
      clearError: true,
    );
    return true;
  }

  /// Signs in an existing member.
  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    if (identifier.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter your email/phone and password.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final isPhone =
        identifier.trim().startsWith('+') ||
        RegExp(r'^\d+$').hasMatch(identifier.trim());
    final existing = state.user;
    final signedInUser = User(
      id: existing?.id ?? 'usr_cam_001',
      fullName: existing?.fullName ?? 'Ngwa Emmanuel',
      email: isPhone
          ? (existing?.email ?? 'member@njangiva.cm')
          : identifier.trim(),
      phoneNumber: isPhone
          ? identifier.trim()
          : (existing?.phoneNumber ?? '+237 6 70 12 34 56'),
      isPhoneVerified: true,
      avatarBytes: existing?.avatarBytes,
    );

    await _tokenStorage.saveTokens(
      AuthTokenPair(
        accessToken: 'njangi_jwt_${signedInUser.id}',
        refreshToken: 'njangi_refresh_${signedInUser.id}',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 24)),
      ),
    );

    state = state.copyWith(
      user: signedInUser,
      isAuthenticated: true,
      isPendingPhoneVerification: false,
      isLoading: false,
      clearError: true,
    );
    return true;
  }

  /// Integration-ready OAuth handler for Google and Facebook sign-in.
  /// Does not fake social login; reports clearly that native/web OAuth provider
  /// configuration is required in production.
  Future<String> initiateOAuthSignIn(String providerName) async {
    return '$providerName OAuth handler is integration-ready. Configure OAuth client credentials on the backend to enable live $providerName sign-in.';
  }

  void updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    Uint8List? avatarBytes,
  }) {
    final current = state.user;
    if (current == null) return;
    state = state.copyWith(
      user: current.copyWith(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        avatarBytes: avatarBytes,
      ),
    );
  }

  Future<void> signOut() async {
    await _tokenStorage.clearTokens();
    state = state.copyWith(
      isAuthenticated: false,
      isPendingPhoneVerification: false,
      clearError: true,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(tokenStorage: ref.watch(tokenStorageProvider));
  },
);
