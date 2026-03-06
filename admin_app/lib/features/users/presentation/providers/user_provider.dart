import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../../../core/network/dio_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UserRepository(dio);
});

final usersProvider = FutureProvider<List<AppUser>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUsers();
});

final systemLogsProvider = FutureProvider<List<SystemLog>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getSystemLogs();
});

final platformOverviewProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getPlatformOverview();
});

enum UserFilter { all, personal, business, active }

class UserFilterNotifier extends Notifier<UserFilter> {
  @override
  UserFilter build() => UserFilter.all;

  void setFilter(UserFilter filter) {
    state = filter;
  }
}

final userFilterProvider = NotifierProvider<UserFilterNotifier, UserFilter>(
  () => UserFilterNotifier(),
);

class UserSearchNotifier extends Notifier<String> {
  @override
  String build() => "";

  void updateQuery(String query) {
    state = query;
  }
}

final userSearchProvider = NotifierProvider<UserSearchNotifier, String>(
  () => UserSearchNotifier(),
);

final filteredUsersProvider = Provider<List<AppUser>>((ref) {
  final filter = ref.watch(userFilterProvider);
  final searchQuery = ref.watch(userSearchProvider).toLowerCase();
  final usersAsyncValue = ref.watch(usersProvider);

  return usersAsyncValue.maybeWhen(
    data: (users) {
      return users.where((u) {
        bool typeMatch = true;
        if (filter == UserFilter.personal)
          typeMatch = u.type == UserType.personal;
        else if (filter == UserFilter.business)
          typeMatch = u.type == UserType.business;
        else if (filter == UserFilter.active)
          typeMatch = u.status == UserStatus.active;

        bool searchMatch =
            u.name.toLowerCase().contains(searchQuery) ||
            u.email.toLowerCase().contains(searchQuery);

        return typeMatch && searchMatch;
      }).toList();
    },
    orElse: () => [],
  );
});
