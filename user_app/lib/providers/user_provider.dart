import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final profileRes = await authService.fetchProfile();
      if (profileRes['success'] == true && profileRes['user'] != null) {
        return UserModel.fromJson(
          Map<String, dynamic>.from(profileRes['user'] as Map),
        );
      }

      final user = authService.currentUser;
      if (user != null) {
        return UserModel(
          id: '', 
          firebaseId: user.uid ?? '',
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
