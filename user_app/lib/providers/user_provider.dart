import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

import '../models/user_model.dart';

/// Notifier to manage the User Profile reactively.
class UserProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() async {
    return _fetchProfile();
  }

  /// Fetches the profile from the backend API.
  Future<UserModel?> _fetchProfile() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      final userId = user?.uid;
      final phoneNumber = user?.phoneNumber ?? '';

      if (phoneNumber.isNotEmpty) {
        final apiService = ref.read(apiServiceProvider);
        final encodedPhone = Uri.encodeComponent(phoneNumber);
        final response = await apiService.getWithFallback(
          '/api/auth/profile?mobileNumber=$encodedPhone',
          '/api/user/profile/$encodedPhone',
        );

        if (response != null && response['user'] != null) {
          final userData = Map<String, dynamic>.from(response['user']);
          // Ensure firebaseId is set from current user if missing
          if (userData['firebaseId'] == null && userId != null) {
            userData['firebaseId'] = userId;
          }
          return UserModel.fromJson(userData);
        }
      }

      if (userId != null) {
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.getWithFallback(
          '/api/auth/profile?uid=${Uri.encodeQueryComponent(userId)}',
          '/api/user/profile?uid=${Uri.encodeQueryComponent(userId)}',
        );

        if (response != null && response['user'] != null) {
          final userData = Map<String, dynamic>.from(response['user']);
          if (userData['firebaseId'] == null) {
            userData['firebaseId'] = userId;
          }
          return UserModel.fromJson(userData);
        }
      }
      
      if (user != null) {
        return UserModel(
          id: '', 
          firebaseId: user.uid,
          email: user.email ?? '',
          name: user.displayName,
          phoneNumber: user.phoneNumber,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Refreshes the state by manually re-fetching.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }
}

/// A global provider for the full user profile.
final fullUserProfileProvider = AsyncNotifierProvider.autoDispose<UserProfileNotifier, UserModel?>(() {
  return UserProfileNotifier();
});

/// A compatibility provider for the user's display name.
final userProfileProvider = Provider.autoDispose<AsyncValue<String>>((ref) {
  final fullProfile = ref.watch(fullUserProfileProvider);
  return fullProfile.whenData((user) => user?.name ?? 'Transglobal User');
});
