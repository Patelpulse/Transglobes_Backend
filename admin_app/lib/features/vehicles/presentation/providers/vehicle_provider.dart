import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/vehicle.dart';
import '../../data/repositories/vehicle_repository.dart';

import '../../../../core/network/dio_provider.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VehicleRepository(dio);
});

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final repository = ref.watch(vehicleRepositoryProvider);
  return repository.getVehicles();
});

enum VehicleFilter { all, cab, truck, bus }

class VehicleFilterNotifier extends Notifier<VehicleFilter> {
  @override
  VehicleFilter build() => VehicleFilter.all;

  void setFilter(VehicleFilter filter) {
    state = filter;
  }
}

final vehicleFilterProvider =
    NotifierProvider<VehicleFilterNotifier, VehicleFilter>(
      () => VehicleFilterNotifier(),
    );

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => "";

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  () => SearchQueryNotifier(),
);

class StatusFilterNotifier extends Notifier<VehicleStatus?> {
  @override
  VehicleStatus? build() => null;

  void setFilter(VehicleStatus? status) {
    state = status;
  }
}

final statusFilterProvider =
    NotifierProvider<StatusFilterNotifier, VehicleStatus?>(
      () => StatusFilterNotifier(),
    );

class NeedsInspectionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final needsInspectionProvider = NotifierProvider<NeedsInspectionNotifier, bool>(
  () => NeedsInspectionNotifier(),
);

final filteredVehiclesProvider = Provider<List<Vehicle>>((ref) {
  final filter = ref.watch(vehicleFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);
  final needsInspection = ref.watch(needsInspectionProvider);
  final vehiclesAsyncValue = ref.watch(vehiclesProvider);

  return vehiclesAsyncValue.maybeWhen(
    data: (vehicles) {
      return vehicles.where((v) {
        bool typeMatch = false;
        if (filter == VehicleFilter.all)
          typeMatch = true;
        else if (filter == VehicleFilter.cab)
          typeMatch = v.type == VehicleType.cab;
        else if (filter == VehicleFilter.truck)
          typeMatch = v.type == VehicleType.truck;
        else if (filter == VehicleFilter.bus)
          typeMatch = v.type == VehicleType.bus;

        bool searchMatch =
            v.name.toLowerCase().contains(searchQuery) ||
            v.plateNumber.toLowerCase().contains(searchQuery) ||
            v.vin.toLowerCase().contains(searchQuery);
        bool statusMatch = statusFilter == null || v.status == statusFilter;
        bool inspectionMatch = !needsInspection || v.needsInspection;
        bool expiredMatch = statusFilter == VehicleStatus.expired
            ? v.status == VehicleStatus.expired
            : true;

        return typeMatch &&
            searchMatch &&
            statusMatch &&
            inspectionMatch &&
            expiredMatch;
      }).toList();
    },
    orElse: () => [],
  );
});
