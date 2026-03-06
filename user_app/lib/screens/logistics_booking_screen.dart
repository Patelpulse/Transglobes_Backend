import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/leaflet_map.dart';
import 'ride_tracking_screen.dart';

class LogisticsBookingScreen extends StatefulWidget {
  const LogisticsBookingScreen({super.key});

  @override
  State<LogisticsBookingScreen> createState() => _LogisticsBookingScreenState();
}

class _LogisticsBookingScreenState extends State<LogisticsBookingScreen> {
  String _selectedVehicle = "3-Wheeler";
  int _quantity = 1;
  final TextEditingController _goodsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final List<Map<String, dynamic>> _vehicles = [
    {
      "name": "3-Wheeler",
      "capacity": "500kg",
      "price": 300.0,
      "imageUrl":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuDTgZx-4-IIUJazZ38EKOWvWqdDD7Tk3YlRgKvC6vvcwqKMkT2z7CtVuI1A2_6CrQSYzIPCbtSPWgQff_1R_0ZLui7glBENZkL1ALQx8ou-vUzxxl1HQwd90iui7HjUbfmVLdq8uTX-73jdR3TP-Zu3ZuYl4LDqCCCRkgFmQ6u-a_HXbEsbdeS6DW4BkgZnA7HDhL73JnNfnN4yweAaKoGqyHvSV7dOxIBAQEo4y6f6NSk2dXonjH5dd1KtY84veLmr0cWScZ_jjhQ",
    },
    {
      "name": "Pickup",
      "capacity": "1.5 tons",
      "price": 650.0,
      "imageUrl":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuClS_sbHIygZYOq7Zj8RzOotC28_JjkE7tuEihpvPFQSHneYrXGw70Np2ARDbH1QTOWGJwgEOfjCwKeMqZEwswID7wCvrlJf34H4tM-g3sWOC5-vsVRhKOFOIKbqxTBbvMrI_ieuhvn7rEFsCjQ1whTk6YLM885BW0K0m2W5DRLNNHEUwityM17qrCzPrOtlWdpZM8ryzTFnJJ570cvV51ZGwVN4EnSirUvJG0qhZWo-hKIcBTL7cQGAFNZwEk3URTMGKUTQ2nQVzM",
    },
    {
      "name": "Tata Ace",
      "capacity": "750kg",
      "price": 450.0,
      "imageUrl":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuCkp7edOsBnAvp5WGBLCCEUtbKz0JE-C26_FrpnQJ4EbFa8WvAu-rg-6K_Oas0wsoF_WahDO04K2l2MTEBfYAEvPCISYLyQOw8vV7ctOSdLxK6RAVjfPrtMaRjxTFSQGp2KoExBXQTtDDB1iy3oiN-98o3KyuuxH4Qn4c76NomMyoUAQbMBkPrHs9JAxAverOxnMSkxHI3SQFVBN7JUyWLaIxGeGmv8MGKYV1-JEIpT9GlhrB7URTjeVx2P6Q96PH2nLysn6LSr_j4",
    },
  ];

  double get _totalPrice {
    final vehicle = _vehicles.firstWhere((v) => v['name'] == _selectedVehicle);
    return (vehicle['price'] as double) * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: context.colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Book Truck",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Section
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.theme.dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const LeafletMap(location: null, markers: []),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      "Select Vehicle Type",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),

                  // Vehicle Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _vehicles.map((vehicle) {
                        final isSelected = _selectedVehicle == vehicle['name'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () =>
                                  _selectedVehicle = vehicle['name'] as String,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.theme.primaryColor.withOpacity(
                                        0.15,
                                      )
                                    : context.theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? context.theme.primaryColor
                                      : context.theme.dividerColor.withOpacity(
                                          0.1,
                                        ),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      vehicle['imageUrl'] as String,
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vehicle['name'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    vehicle['capacity'] as String,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${(vehicle['price'] as double).toInt()}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: context.theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      "Load Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),

                  // Load Details Form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Type of Goods",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _goodsController,
                          style: TextStyle(color: context.colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Furniture, Electronics, Groceries...",
                            hintStyle: TextStyle(
                              color: context.colors.textSecondary?.withOpacity(
                                0.5,
                              ),
                            ),
                            fillColor: context.theme.cardColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Weight (kg)",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _weightController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "e.g. 450",
                                      hintStyle: TextStyle(
                                        color: context.colors.textSecondary
                                            ?.withOpacity(0.5),
                                      ),
                                      fillColor: context.theme.cardColor,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Quantity",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: context.theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove,
                                            size: 18,
                                            color: context.theme.primaryColor,
                                          ),
                                          onPressed: () {
                                            if (_quantity > 1)
                                              setState(() => _quantity--);
                                          },
                                        ),
                                        Text(
                                          "$_quantity",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            size: 18,
                                            color: context.theme.primaryColor,
                                          ),
                                          onPressed: () =>
                                              setState(() => _quantity++),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estimated Total",
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "₹${_totalPrice.toInt()}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(
                          Icons.confirmation_num_outlined,
                          color: context.theme.primaryColor,
                          size: 18,
                        ),
                        label: Text(
                          "Apply Coupon",
                          style: TextStyle(
                            color: context.theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideTrackingScreen(
                            pickup: const {
                              "address": "Local Warehouse",
                              "lat": 19.0760,
                              "lng": 72.8777,
                            },
                            dropoff: const {
                              "address": "Client Location",
                              "lat": 19.0800,
                              "lng": 72.8800,
                            },
                            vehicle: {
                              "name": _selectedVehicle,
                              "type": "Truck",
                            },
                            rideId:
                                "LOG-${DateTime.now().millisecondsSinceEpoch}",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Book $_selectedVehicle Now",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
