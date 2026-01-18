import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<ServiceType> services;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.services,
  });
}

class ServiceType {
  final String id;
  final String name;
  final String description;
  final double estimatedPrice;
  final int estimatedDurationMinutes;

  const ServiceType({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedPrice,
    required this.estimatedDurationMinutes,
  });
}

class ServiceCategories {
  static const List<ServiceCategory> categories = [
    ServiceCategory(
      id: 'routine',
      name: 'Routine Maintenance',
      icon: Icons.settings,
      color: Colors.blue,
      services: [
        ServiceType(
          id: 'oil_change',
          name: 'Oil Change',
          description: 'Engine oil and filter replacement',
          estimatedPrice: 1500,
          estimatedDurationMinutes: 45,
        ),
        ServiceType(
          id: 'filter_replacement',
          name: 'Filter Replacement',
          description: 'Air filter, fuel filter, cabin filter',
          estimatedPrice: 800,
          estimatedDurationMinutes: 30,
        ),
        ServiceType(
          id: 'fluid_topup',
          name: 'Fluid Top-up',
          description: 'Coolant, brake fluid, windshield washer',
          estimatedPrice: 500,
          estimatedDurationMinutes: 20,
        ),
      ],
    ),
    ServiceCategory(
      id: 'brakes',
      name: 'Brake System',
      icon: Icons.car_crash,
      color: Colors.red,
      services: [
        ServiceType(
          id: 'brake_pads',
          name: 'Brake Pad Replacement',
          description: 'Front or rear brake pad replacement',
          estimatedPrice: 3500,
          estimatedDurationMinutes: 90,
        ),
        ServiceType(
          id: 'brake_fluid',
          name: 'Brake Fluid Change',
          description: 'Complete brake fluid replacement',
          estimatedPrice: 1200,
          estimatedDurationMinutes: 40,
        ),
        ServiceType(
          id: 'brake_inspection',
          name: 'Brake Inspection',
          description: 'Complete brake system check',
          estimatedPrice: 500,
          estimatedDurationMinutes: 30,
        ),
      ],
    ),
    ServiceCategory(
      id: 'tires',
      name: 'Tire Services',
      icon: Icons.album,
      color: Colors.orange,
      services: [
        ServiceType(
          id: 'tire_rotation',
          name: 'Tire Rotation',
          description: 'Rotate all four tires for even wear',
          estimatedPrice: 800,
          estimatedDurationMinutes: 30,
        ),
        ServiceType(
          id: 'wheel_alignment',
          name: 'Wheel Alignment',
          description: 'Front and rear wheel alignment',
          estimatedPrice: 2000,
          estimatedDurationMinutes: 60,
        ),
        ServiceType(
          id: 'tire_replacement',
          name: 'Tire Replacement',
          description: 'Replace one or more tires',
          estimatedPrice: 5000,
          estimatedDurationMinutes: 45,
        ),
      ],
    ),
    ServiceCategory(
      id: 'engine',
      name: 'Engine & Performance',
      icon: Icons.speed,
      color: Colors.purple,
      services: [
        ServiceType(
          id: 'engine_diagnostics',
          name: 'Engine Diagnostics',
          description: 'Complete engine diagnostic scan',
          estimatedPrice: 1500,
          estimatedDurationMinutes: 60,
        ),
        ServiceType(
          id: 'tune_up',
          name: 'Engine Tune-up',
          description: 'Spark plugs, ignition system check',
          estimatedPrice: 3000,
          estimatedDurationMinutes: 120,
        ),
        ServiceType(
          id: 'performance_check',
          name: 'Performance Check',
          description: 'Overall performance evaluation',
          estimatedPrice: 1000,
          estimatedDurationMinutes: 45,
        ),
      ],
    ),
    ServiceCategory(
      id: 'electrical',
      name: 'Electrical System',
      icon: Icons.battery_charging_full,
      color: Colors.green,
      services: [
        ServiceType(
          id: 'battery_replacement',
          name: 'Battery Replacement',
          description: 'New battery installation',
          estimatedPrice: 4500,
          estimatedDurationMinutes: 30,
        ),
        ServiceType(
          id: 'ac_service',
          name: 'AC Service',
          description: 'AC gas refill and system check',
          estimatedPrice: 2500,
          estimatedDurationMinutes: 60,
        ),
        ServiceType(
          id: 'electrical_diagnostics',
          name: 'Electrical Diagnostics',
          description: 'Electrical system troubleshooting',
          estimatedPrice: 1500,
          estimatedDurationMinutes: 90,
        ),
      ],
    ),
    ServiceCategory(
      id: 'body',
      name: 'Body & Paint',
      icon: Icons.brush,
      color: Colors.teal,
      services: [
        ServiceType(
          id: 'denting_painting',
          name: 'Denting & Painting',
          description: 'Body dent removal and painting',
          estimatedPrice: 8000,
          estimatedDurationMinutes: 480,
        ),
        ServiceType(
          id: 'detailing',
          name: 'Car Detailing',
          description: 'Interior and exterior detailing',
          estimatedPrice: 3500,
          estimatedDurationMinutes: 180,
        ),
        ServiceType(
          id: 'rust_treatment',
          name: 'Rust Treatment',
          description: 'Rust removal and protection',
          estimatedPrice: 5000,
          estimatedDurationMinutes: 240,
        ),
      ],
    ),
    ServiceCategory(
      id: 'general',
      name: 'General Services',
      icon: Icons.build,
      color: Colors.blueGrey,
      services: [
        ServiceType(
          id: 'full_inspection',
          name: 'Full Vehicle Inspection',
          description: 'Comprehensive vehicle check-up',
          estimatedPrice: 2000,
          estimatedDurationMinutes: 120,
        ),
        ServiceType(
          id: 'custom_service',
          name: 'Custom Service',
          description: 'Describe your specific requirements',
          estimatedPrice: 0,
          estimatedDurationMinutes: 60,
        ),
      ],
    ),
  ];

  static List<ServiceType> getAllServices() {
    return categories.expand((category) => category.services).toList();
  }

  static ServiceType? getServiceById(String id) {
    try {
      return getAllServices().firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }

  static ServiceCategory? getCategoryForService(String serviceId) {
    for (var category in categories) {
      if (category.services.any((s) => s.id == serviceId)) {
        return category;
      }
    }
    return null;
  }
}

// Time slots for booking
class TimeSlots {
  static const List<String> slots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  static TimeOfDay parseTimeSlot(String slot) {
    final parts = slot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1] == 'PM';

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  static bool isSlotAvailable(String slot, DateTime selectedDate) {
    final now = DateTime.now();
    final slotTime = parseTimeSlot(slot);
    final slotDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      slotTime.hour,
      slotTime.minute,
    );

    return slotDateTime.isAfter(now);
  }
}
