import 'package:flutter/material.dart';

class AddressEntry {
  final String id;
  final String label;
  final String fullAddress;
  final String? houseNumber;
  final String? floorNumber;
  final String? landmark;
  final String city;
  final String pincode;
  final String? phone;
  final String? email;
  final String type; // 'pickup' or 'received'
  final IconData icon;

  AddressEntry({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.houseNumber,
    this.floorNumber,
    this.landmark,
    required this.city,
    required this.pincode,
    this.phone,
    this.email,
    required this.type,
    required this.icon,
  });
}
