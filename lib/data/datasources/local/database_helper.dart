// lib/data/datasources/local/database_helper.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, AppConstants.dbName);

    bool fileExists = await File(path).exists();

    if (!fileExists) {
      ByteData data = await rootBundle.load("assets/${AppConstants.dbName}");
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  Future<List<Map<String, dynamic>>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = AppConstants.maxMarkersToShow,
  }) async {
    Database db = await database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'Geolocations',
        columns: ['stationId', 'lat', 'lon'],
        where: 'lat >= ? AND lat <= ? AND lon >= ? AND lon <= ?',
        whereArgs: [minLat, maxLat, minLon, maxLon],
        limit: limit,
      );

      return result;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSampleStations({int limit = 10}) async {
    Database db = await database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'Geolocations',
        columns: ['stationId', 'lat', 'lon'],
        limit: limit,
        orderBy: 'RANDOM()',
      );

      return result;
    } catch (e) {
      return [];
    }
  }

  Future<int> getStationCount() async {
    Database db = await database;

    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM Geolocations',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
