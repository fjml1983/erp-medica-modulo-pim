import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._internal();
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  static Database? _database;

  static const String _dbName = 'catalogos.db';
  static const String _assetPath = 'assets/catalogos.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, _dbName);

    final dbFile = File(path);
    if (!await dbFile.exists()) {
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List();
      await Directory(dirname(path)).create(recursive: true);
      await dbFile.writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  Future<void> forceRecopy() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, _dbName);
    if (await File(path).exists()) {
      await deleteDatabase(path);
    }
    _database = null;
    await database;
  }

  
  Future<bool> _hasColumn(Database db, String table, String column) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((c) => (c['name'] ?? '').toString().toLowerCase() == column.toLowerCase());
  }

  
  Future<List<Map<String, dynamic>>> getEntidades() async {
    final db = await database;
    return await db.query('entidades', orderBy: 'nombre COLLATE NOCASE ASC');
  }

  
  Future<List<Map<String, dynamic>>> getMunicipios(String claveEntidad) async {
    final db = await database;
    return await db.query(
      'municipios',
      where: 'clave_entidad = ?',
      whereArgs: [claveEntidad],
    );
  }

  
  Future<List<Map<String, dynamic>>> getCodigosPostalesSmart({
    required String cEstado,       
    required String cMnpio3,       
    String? municipioNombre,        
  }) async {
    final db = await database;

    
    final cMnpio3Pad = cMnpio3.padLeft(3, '0');
    final cMnpioInt = int.tryParse(cMnpio3) ?? int.tryParse(cMnpio3Pad);
    final combinado = '$cEstado$cMnpio3Pad'; 

    
    final hasCEstado = await _hasColumn(db, 'codigos_postales', 'c_estado');
    final hasCMnpio  = await _hasColumn(db, 'codigos_postales', 'c_mnpio');
    final hasMunId   = await _hasColumn(db, 'codigos_postales', 'municipio_id');
    final hasDMnpio  = await _hasColumn(db, 'codigos_postales', 'd_mnpio');

    
    if (hasCEstado && hasCMnpio) {
      final a1 = await db.query(
        'codigos_postales',
        where: 'c_estado = ? AND c_mnpio = ?',
        whereArgs: [cEstado, cMnpio3Pad],
        orderBy: 'CAST(d_codigo AS INT) ASC',
      );
      if (a1.isNotEmpty) {
        return a1;
      }
      
      if (cMnpioInt != null) {
        final a2 = await db.query(
          'codigos_postales',
          where: 'c_estado = ? AND c_mnpio = ?',
          whereArgs: [cEstado, cMnpioInt],
          orderBy: 'CAST(d_codigo AS INT) ASC',
        );
        if (a2.isNotEmpty) {
          return a2;
        }
      }
    }

    
    if (hasMunId) {
      
      final b1 = await db.query(
        'codigos_postales',
        where: 'municipio_id = ?',
        whereArgs: [combinado],
        orderBy: 'CAST(d_codigo AS INT) ASC',
      );
      if (b1.isNotEmpty) {
        
        return b1;
      }
      
      final combInt = int.tryParse(combinado);
      if (combInt != null) {
        final b2 = await db.query(
          'codigos_postales',
          where: 'municipio_id = ?',
          whereArgs: [combInt],
          orderBy: 'CAST(d_codigo AS INT) ASC',
        );
        if (b2.isNotEmpty) {
          
          return b2;
        }
      }
    }

    
    if (municipioNombre != null && municipioNombre.trim().isNotEmpty && hasCEstado && hasDMnpio) {
      final c1 = await db.query(
        'codigos_postales',
        where: 'c_estado = ? AND lower(d_mnpio) = lower(?)',
        whereArgs: [cEstado, municipioNombre.trim()],
        orderBy: 'CAST(d_codigo AS INT) ASC',
      );
      if (c1.isNotEmpty) {
        
        return c1;
      }
    }

    
    return <Map<String, dynamic>>[];
  }
}