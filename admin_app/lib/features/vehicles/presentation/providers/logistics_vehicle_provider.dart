import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/logistics_vehicle_repository.dart';
import '../../domain/models/logistics_vehicle.dart';
import '../../../../core/network/dio_provider.dart';

final logisticsVehicleRepositoryProvider = Provider<LogisticsVehicleRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LogisticsVehicleRepository(dio);
});

final logisticsVehiclesProvider = FutureProvider<List<LogisticsVehicle>>((ref) async {
  final repository = ref.watch(logisticsVehicleRepositoryProvider);
  return repository.getLogisticsVehicles();
});
