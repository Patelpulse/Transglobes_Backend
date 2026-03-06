import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/driver_model.dart';
import '../../data/repositories/driver_repository.dart';
import '../../../../core/network/dio_provider.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DriverRepository(dio);
});

class DriversNotifier extends AsyncNotifier<List<Driver>> {
  @override
  Future<List<Driver>> build() async {
    final repository = ref.watch(driverRepositoryProvider);
    return repository.getDrivers();
  }

  Future<void> getDrivers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.watch(driverRepositoryProvider);
      return repository.getDrivers();
    });
  }

  Future<bool> deleteDriver(String driverId) async {
    final repository = ref.watch(driverRepositoryProvider);
    final success = await repository.deleteDriver(driverId);
    if (success) {
      state.whenData((drivers) {
        state = AsyncValue.data(drivers.where((d) => d.id != driverId).toList());
      });
    }
    return success;
  }

  Future<bool> updateDriverStatus(String driverId, DriverStatus newStatus) async {
    final repository = ref.watch(driverRepositoryProvider);
    final success = await repository.updateDriverStatus(driverId, newStatus);
    if (success) {
      await getDrivers();
    }
    return success;
  }

  Future<bool> warnDriver(String driverId, String reason) async {
    final repository = ref.watch(driverRepositoryProvider);
    final success = await repository.warnDriver(driverId, reason);
    if (success) {
      // Re-fetch to get updated warning limits and potential auto-suspension
      await getDrivers();
    }
    return success;
  }
}

final driversProvider =
    AsyncNotifierProvider<DriversNotifier, List<Driver>>(() {
  return DriversNotifier();
});

enum DriverFilter { all, active, pending, suspended }

class DriverFilterNotifier extends Notifier<DriverFilter> {
  @override
  DriverFilter build() => DriverFilter.all;

  void setFilter(DriverFilter filter) {
    state = filter;
  }
}

final driverFilterProvider = NotifierProvider<DriverFilterNotifier, DriverFilter>(
  () => DriverFilterNotifier(),
);

class DriverSearchNotifier extends Notifier<String> {
  @override
  String build() => "";

  void updateQuery(String query) {
    state = query;
  }
}

final driverSearchProvider = NotifierProvider<DriverSearchNotifier, String>(
  () => DriverSearchNotifier(),
);

final filteredDriversProvider = Provider<List<Driver>>((ref) {
  final filter = ref.watch(driverFilterProvider);
  final searchQuery = ref.watch(driverSearchProvider).toLowerCase();
  final driversAsyncValue = ref.watch(driversProvider);

  return driversAsyncValue.maybeWhen(
    data: (drivers) {
      return drivers.where((d) {
        bool statusMatch = true;
        if (filter == DriverFilter.active)
          statusMatch = d.status == DriverStatus.active;
        else if (filter == DriverFilter.pending)
          statusMatch = d.status == DriverStatus.pending;
        else if (filter == DriverFilter.suspended)
          statusMatch = d.status == DriverStatus.suspended;

        bool searchMatch =
            d.name.toLowerCase().contains(searchQuery) ||
            (d.licenseNumber?.toLowerCase().contains(searchQuery) ?? false);

        return statusMatch && searchMatch;
      }).toList();
    },
    orElse: () => [],
  );
});
