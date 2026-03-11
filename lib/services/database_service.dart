// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/fuel_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fuel_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE fuel_entries (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            odometer_reading REAL NOT NULL,
            liters_filled REAL NOT NULL,
            amount_paid REAL NOT NULL,
            price_per_liter REAL NOT NULL,
            speedometer_image_path TEXT,
            machine_image_path TEXT,
            mileage REAL,
            notes TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertEntry(FuelEntry entry) async {
    final db = await database;
    await db.insert(
      'fuel_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FuelEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query(
      'fuel_entries',
      orderBy: 'date DESC',
    );
    return maps.map((m) => FuelEntry.fromMap(m)).toList();
  }

  Future<List<FuelEntry>> getEntriesOrderedByOdometer() async {
    final db = await database;
    final maps = await db.query(
      'fuel_entries',
      orderBy: 'odometer_reading ASC',
    );
    return maps.map((m) => FuelEntry.fromMap(m)).toList();
  }

  Future<void> updateEntry(FuelEntry entry) async {
    final db = await database;
    await db.update(
      'fuel_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete(
      'fuel_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    final entries = await getEntriesOrderedByOdometer();

    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'totalLiters': 0.0,
        'totalAmount': 0.0,
        'averageMileage': 0.0,
        'bestMileage': 0.0,
        'worstMileage': 0.0,
        'totalDistance': 0.0,
      };
    }

    double totalLiters = entries.fold(0.0, (sum, e) => sum + e.litersFilled);
    double totalAmount = entries.fold(0.0, (sum, e) => sum + e.amountPaid);

    // Calculate mileage between consecutive entries
    List<double> mileages = [];
    for (int i = 1; i < entries.length; i++) {
      final distance = entries[i].odometerReading - entries[i - 1].odometerReading;
      if (distance > 0 && entries[i].litersFilled > 0) {
        mileages.add(distance / entries[i].litersFilled);
      }
    }

    double avgMileage = mileages.isNotEmpty
        ? mileages.reduce((a, b) => a + b) / mileages.length
        : 0.0;

    double bestMileage = mileages.isNotEmpty ? mileages.reduce((a, b) => a > b ? a : b) : 0.0;
    double worstMileage = mileages.isNotEmpty ? mileages.reduce((a, b) => a < b ? a : b) : 0.0;

    double totalDistance = entries.isNotEmpty
        ? entries.last.odometerReading - entries.first.odometerReading
        : 0.0;

    return {
      'totalEntries': entries.length,
      'totalLiters': totalLiters,
      'totalAmount': totalAmount,
      'averageMileage': avgMileage,
      'bestMileage': bestMileage,
      'worstMileage': worstMileage,
      'totalDistance': totalDistance,
    };
  }

  // Calculate mileage for each entry based on consecutive readings
  Future<List<FuelEntry>> getEntriesWithMileage() async {
    final entries = await getEntriesOrderedByOdometer();

    List<FuelEntry> result = [];
    for (int i = 0; i < entries.length; i++) {
      if (i == 0) {
        result.add(entries[i]);
      } else {
        final distance = entries[i].odometerReading - entries[i - 1].odometerReading;
        double? mileage;
        if (distance > 0 && entries[i].litersFilled > 0) {
          mileage = distance / entries[i].litersFilled;
        }
        result.add(entries[i].copyWith(mileage: mileage));
      }
    }
    return result.reversed.toList();
  }
}
