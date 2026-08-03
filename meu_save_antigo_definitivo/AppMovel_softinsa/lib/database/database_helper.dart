import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'database_schema.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _databaseName = 'softinsa_mobile.db';
  static const int databaseVersion = 3;

  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null && current.isOpen) return current;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    final path = p.join(root, _databaseName);
    return openDatabase(
      path,
      version: databaseVersion,
      onConfigure: (db) async {
        // Disable foreign keys during configure so upgrades/drops can run without constraint violations
        await db.execute('PRAGMA foreign_keys = OFF');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop tables in dependency order
        final tables = [
          DatabaseSchema.badgesRequisitosTable,
          DatabaseSchema.documentosSubmissaoTable,
          DatabaseSchema.badgesAssinaturaTable,
          DatabaseSchema.submissaoRequisitosTable,
          DatabaseSchema.historicoTable,
          DatabaseSchema.objetivosTable,
          DatabaseSchema.submissoesTable,
          DatabaseSchema.registoBadgesTable,
          DatabaseSchema.outrosUsersTable,
          
          DatabaseSchema.requisitosTable,
          DatabaseSchema.badgesTable,
          DatabaseSchema.assinaturaTable,
          DatabaseSchema.notificacoesTable,
          DatabaseSchema.areasTable,
          DatabaseSchema.serviceLinesTable,
          DatabaseSchema.learningPathsTable,
          DatabaseSchema.niveisTable,
          DatabaseSchema.permissoesTable,
          DatabaseSchema.perfilTable,
          DatabaseSchema.syncStateTable,
          DatabaseSchema.syncOutboxTable,
        ];
        for (final table in tables) {
          await db.execute('DROP TABLE IF EXISTS $table');
        }
        await _createTables(db);
      },
      onOpen: (db) async {
        // Re-enable foreign keys after opening/upgrading successfully
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db) async {
    final tables = [
      DatabaseSchema.createSyncStateTable,
      DatabaseSchema.createSyncOutboxTable,
      DatabaseSchema.createPerfilTable,
      DatabaseSchema.createBadgesTable,
      DatabaseSchema.createRequisitosTable,
      DatabaseSchema.createBadgesRequisitosTable,
      DatabaseSchema.createSubmissoesTable,
      DatabaseSchema.createDocumentosTable,
      DatabaseSchema.createHistoricoTable,
      DatabaseSchema.createObjetivosTable,
      DatabaseSchema.createAssinaturaTable,
      DatabaseSchema.createBadgesAssinaturaTable,
      DatabaseSchema.createNotificacoesTable,
      DatabaseSchema.createRegistoBadgesTable,
      DatabaseSchema.createAreasTable,
      DatabaseSchema.createServiceLinesTable,
      DatabaseSchema.createUsersTable,
      DatabaseSchema.createLearningPathsTable,
      DatabaseSchema.createNiveisTable,
      DatabaseSchema.createPermissoesTable,
      DatabaseSchema.createSubmissaoRequisitosTable,
    ];
    for (final statement in tables) {
      await db.execute(statement);
    }
    // Create indexes
    for (final statement in DatabaseSchema.createIndexes) {
      await db.execute(statement);
    }
  }
}