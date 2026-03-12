enum TransportMode { land, air, water }

enum VehicleType {
  // Land Vehicles
  miniTruck('Mini Truck', 40, 1000, 'Small local deliveries', TransportMode.land),
  cargoXL('Cargo XL', 80, 5000, 'Standard medium freight', TransportMode.land),
  multiAxle('Multi-axle', 150, 20000, 'Heavy industrial haulage', TransportMode.land),
  
  // Air Vehicles
  smallPlane('Propeller Cargo', 500, 2000, 'Quick regional air freight', TransportMode.air),
  bigPlane('Boeing 747-F', 2000, 100000, 'Global massive air transport', TransportMode.air),
  
  // Water Vehicles
  barge('Coastal Barge', 300, 50000, 'River and coastal transport', TransportMode.water),
  cargoShip('Ocean Freighter', 1200, 500000, 'Global sea-lane shipping', TransportMode.water);

  final String label;
  final double basePrice;
  final double maxWeight;
  final String description;
  final TransportMode mode;

  const VehicleType(this.label, this.basePrice, this.maxWeight, this.description, this.mode);
}

class LogisticsRequest {
  final String id;
  final String pickupLocation;
  final String destinationLocation;
  final double weight;
  final String goodsType;
  final List<TransportMode> modes; // Changed to List
  final Map<TransportMode, VehicleType> selectedVehicles; // Changed to Map
  final double estimatedPrice;
  final String status;
  final DateTime createdAt;

  LogisticsRequest({
    required this.id,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.weight,
    required this.goodsType,
    required this.modes,
    required this.selectedVehicles,
    required this.estimatedPrice,
    this.status = 'Pending Supervisor',
    required this.createdAt,
  });
}
