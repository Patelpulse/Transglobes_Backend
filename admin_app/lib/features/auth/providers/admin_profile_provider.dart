import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/admin_model.dart';
import '../providers/auth_provider.dart';

final adminProfileProvider = FutureProvider<AdminProfile>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final result = await authService.getProfile();
  
  if (result['success']) {
    return AdminProfile.fromMap(result['data']['admin']);
  } else {
    throw Exception(result['message'] ?? 'Failed to load profile');
  }
});

class AdminProfileNotifier extends AsyncNotifier<AdminProfile> {
  @override
  Future<AdminProfile> build() async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.getProfile();
    if (result['success']) {
      return AdminProfile.fromMap(result['data']['admin']);
    } else {
      throw Exception(result['message'] ?? 'Failed to load profile');
    }
  }

  Future<bool> updatePhoto(List<int> bytes, String fileName) async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.updateProfilePhoto(bytes, fileName);
    if (result['success']) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> changePassword(String current, String next) async {
    final authService = ref.read(authServiceProvider);
    return await authService.changePassword(current, next);
  }
}

final adminProfileNotifierProvider = AsyncNotifierProvider<AdminProfileNotifier, AdminProfile>(() {
  return AdminProfileNotifier();
});
