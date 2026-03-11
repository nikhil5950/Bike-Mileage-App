// lib/models/fuel_entry.dart

class FuelEntry {
  final String id;
  final DateTime date;
  final double odometerReading;
  final double litersFilled;
  final double amountPaid;
  final double pricePerLiter;
  final String? speedometerImagePath;
  final String? machineImagePath;
  final double? mileage; // km/liter for this entry
  final String? notes;

  FuelEntry({
    required this.id,
    required this.date,
    required this.odometerReading,
    required this.litersFilled,
    required this.amountPaid,
    required this.pricePerLiter,
    this.speedometerImagePath,
    this.machineImagePath,
    this.mileage,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'odometer_reading': odometerReading,
      'liters_filled': litersFilled,
      'amount_paid': amountPaid,
      'price_per_liter': pricePerLiter,
      'speedometer_image_path': speedometerImagePath,
      'machine_image_path': machineImagePath,
      'mileage': mileage,
      'notes': notes,
    };
  }

  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      odometerReading: (map['odometer_reading'] as num).toDouble(),
      litersFilled: (map['liters_filled'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      pricePerLiter: (map['price_per_liter'] as num).toDouble(),
      speedometerImagePath: map['speedometer_image_path'],
      machineImagePath: map['machine_image_path'],
      mileage: map['mileage'] != null ? (map['mileage'] as num).toDouble() : null,
      notes: map['notes'],
    );
  }

  FuelEntry copyWith({
    String? id,
    DateTime? date,
    double? odometerReading,
    double? litersFilled,
    double? amountPaid,
    double? pricePerLiter,
    String? speedometerImagePath,
    String? machineImagePath,
    double? mileage,
    String? notes,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      odometerReading: odometerReading ?? this.odometerReading,
      litersFilled: litersFilled ?? this.litersFilled,
      amountPaid: amountPaid ?? this.amountPaid,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      speedometerImagePath: speedometerImagePath ?? this.speedometerImagePath,
      machineImagePath: machineImagePath ?? this.machineImagePath,
      mileage: mileage ?? this.mileage,
      notes: notes ?? this.notes,
    );
  }
}

class ExtractedData {
  final double? odometerReading;
  final double? litersFilled;
  final double? amountPaid;
  final double? pricePerLiter;
  final String? rawText;
  final bool success;
  final String? errorMessage;

  ExtractedData({
    this.odometerReading,
    this.litersFilled,
    this.amountPaid,
    this.pricePerLiter,
    this.rawText,
    required this.success,
    this.errorMessage,
  });
}
