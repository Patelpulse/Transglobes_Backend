import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Notifier to manage the User Profile name reactively.
/// Using [AsyncNotifier] for Riverpod 3.x compatibility.
class UserProfileNotifier extends AsyncNotifier<String> {
  @override
  FutureOr<String> build() async {
    return _fetchProfile();
  }

  /// Fetches the profile from the backend API.
  Future<String> _fetchProfile() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      final phoneNumber = user?.phoneNumber ?? '';

      if (phoneNumber.isNotEmpty) {
        final apiService = ref.read(apiServiceProvider);
        final encodedPhone = Uri.encodeComponent(phoneNumber);
        final response = await apiService.get('/api/user/profile/$encodedPhone');

        if (response != null && response['user'] != null) {
          final name = response['user']['name'] ?? '';
          if (name.toString().trim().isNotEmpty) {
            return name.toString();
          }
        }
      }
      
      // Fallback to Firebase profile name or default placeholder
      return user?.displayName ?? 'Transglobal User';
    } catch (e) {
      // In case of error (e.g. network down), fallback silently to keep UI stable
      final user = ref.read(authServiceProvider).currentUser;
      return user?.displayName ?? 'Transglobal User';
    }
  }

  /// Refreshes the state by manually re-fetching.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }

  /// Optimistically update the UI after a successful name save.
  void updateNameLocally(String newName) {
    state = AsyncValue.data(newName);
  }
}

/// A global provider for the user's display name.
/// We use the [.autoDispose] modifier to clean up when not in use.
final userProfileProvider = AsyncNotifierProvider.autoDispose<UserProfileNotifier, String>(() {
  return UserProfileNotifier();
});
