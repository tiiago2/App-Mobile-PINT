import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../database/database_schema.dart';
import '../database/daos/perfil_dao.dart';
import '../database/daos/sync_outbox_dao.dart';
import '../database/daos/assinaturas_dao.dart';
import '../database/daos/badges_dao.dart';
import 'auth_controller.dart';
import '../database/sync_helpers.dart';

class PerfilController extends ChangeNotifier {
  PerfilController._() {
    AuthController.instance.addListener(_handleAuthChanged);
  }

  static final PerfilController instance = PerfilController._();

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? _perfilData;
  List<int> _signatureBadgeIds = const [];
  List<Map<String, dynamic>> _conqueredBadges = const [];
  List<Map<String, dynamic>> _historyBadges = const [];
  Map<String, dynamic>? _learningPathProgress;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get perfilData => _perfilData;
  List<int> get signatureBadgeIds => _signatureBadgeIds;
  List<Map<String, dynamic>> get conqueredBadges => _conqueredBadges;
  List<Map<String, dynamic>> get historyBadges => _historyBadges;
  Map<String, dynamic>? get learningPathProgress => _learningPathProgress;

  void _handleAuthChanged() {
    if (!AuthController.instance.isAuthenticated) {
      _perfilData = null;
      _signatureBadgeIds = const [];
      _conqueredBadges = const [];
      _historyBadges = const [];
      _learningPathProgress = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarDadosPerfil() async {
    final user = AuthController.instance.currentUser;
    final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);

    if (userId == null || userId <= 0) {
      _errorMessage = 'Utilizador não autenticado.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Info Utilizador
      var perfil = await PerfilDao.instance.lerPerfilComArea(userId);

      // Repor area_id se estiver nulo
      if (perfil != null && (perfil['id_area'] == null || perfil['id_area'].toString().isEmpty)) {
        final currentUser = AuthController.instance.currentUser;
        final fallbackAreaId = currentUser?['id_area']?.toString() ?? 
                               (currentUser?['area'] is Map ? currentUser?['area']?['id_area']?.toString() : null) ??
                               currentUser?['area_id']?.toString() ??
                               '6'; // default fallback como 6
        
        debugPrint('⚠️ [PerfilController] id_area nulo no SQLite. A repor para $fallbackAreaId...');
        final db = await DatabaseHelper.instance.database;
        await db.update(
          DatabaseSchema.perfilTable,
          {'id_area': fallbackAreaId},
          where: 'id_utilizador = ?',
          whereArgs: [userId],
        );
        // Recarregar perfil após atualização
        perfil = await PerfilDao.instance.lerPerfilComArea(userId);
      }

      _perfilData = perfil;

      if (perfil != null) {
        final idArea = intOrNull(perfil['id_area']);
        if (idArea != null && idArea > 0) {
          // 4. Learning Path
          _learningPathProgress = await PerfilDao.instance.obterProgressoLearningPath(userId, idArea);
        }
      }

      // 2. Assinatura Digital Badges
      _signatureBadgeIds = await AssinaturasDao.instance.obterIdsBadgesAssinatura(userId);

      // 3. Badges Conquistados
      _conqueredBadges = await BadgesDao.instance.obterBadgesConquistados(userId);

      // 3.1. Histórico de Badges (ativos + expirados)
      _historyBadges = await BadgesDao.instance.obterHistoricoBadges(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar dados locais: $e';
      notifyListeners();
    }
  }

  Future<String> atualizarFotoPerfilLocal(int userId, String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final localFile = File('${appDir.path}/$fileName');
    
    // a) Copiar o ficheiro para o diretório de documentos local da aplicação
    await File(sourcePath).copy(localFile.path);

    // b) Guardar o caminho local na base de dados SQLite
    final db = await DatabaseHelper.instance.database;
    await db.update(
      DatabaseSchema.perfilTable,
      {
        'imagem_perfil': localFile.path,
        'sync_status': 'pending_update',
      },
      where: 'id_utilizador = ?',
      whereArgs: [userId],
    );

    // c) Adicionar um registo na tabela 'sync_outbox'
    await SyncOutboxDao.instance.adicionarOperacao(
      userId: userId,
      entity: 'perfil',
      operation: 'update_foto',
      localRecordId: userId,
      clientId: generateClientId(),
      payload: { 'local_path': localFile.path },
    );

    // d) Atualizar os dados de cache na memória
    if (_perfilData != null) {
      _perfilData = {
        ..._perfilData!,
        'imagem_perfil': localFile.path,
      };
    }
    notifyListeners();
    return localFile.path;
  }

  Future<void> guardarAlteracoesPerfilOffline({
    required int userId,
    required String nome,
    required String email,
    required String telefone,
    required String? idArea,
    required String? fotoLocalPath,
    required String? assinaturaSourcePath,
    required List<int> badgeIdsDisposicao,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    // Preservar o area_id antigo se vier nulo ou vazio no parâmetro
    String? finalIdArea = idArea;
    if (finalIdArea == null || finalIdArea.isEmpty) {
      final existingRows = await db.query(
        DatabaseSchema.perfilTable,
        columns: ['id_area'],
        where: 'id_utilizador = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (existingRows.isNotEmpty) {
        finalIdArea = existingRows.first['id_area']?.toString();
      }
      
      if (finalIdArea == null || finalIdArea.isEmpty) {
        final currentUser = AuthController.instance.currentUser;
        finalIdArea = currentUser?['id_area']?.toString() ?? 
                      (currentUser?['area'] is Map ? currentUser?['area']?['id_area']?.toString() : null) ??
                      currentUser?['area_id']?.toString();
      }
    }

    final perfilMap = {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'id_area': finalIdArea,
      'foto': fotoLocalPath,
    };
    
    final perfilValues = {
      'id_utilizador': userId,
      'nome_user': nome,
      'email': email,
      'telefone': telefone,
      'imagem_perfil': fotoLocalPath,
      'id_area': finalIdArea,
      'profile_json': jsonEncode({...perfilMap, 'id_utilizador': userId}),
      'local_updated_at': utcNow(),
      'sync_status': 'pending_update',
    };

    String? localFilePath = assinaturaSourcePath;
    if (localFilePath != null && localFilePath.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'signature_${userId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final localFile = File('${appDir.path}/$fileName');
      await File(localFilePath).copy(localFile.path);
      localFilePath = localFile.path;
    } else {
      // Tentar recuperar do SQLite se houver
      final existingRows = await db.query(
        DatabaseSchema.assinaturaTable,
        columns: ['update_assinatura'],
        where: 'id_proprietario = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (existingRows.isNotEmpty) {
        localFilePath = existingRows.first['update_assinatura']?.toString();
      }
      
      // Criar mock se for completamente nulo para evitar crash de upload
      if (localFilePath == null || localFilePath.isEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final defaultFile = File('${appDir.path}/signature_${userId}_default.png');
        if (!await defaultFile.exists()) {
          await defaultFile.writeAsBytes([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 108, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 96, 64, 5, 0, 0, 14, 0, 1, 10, 47, 69, 137, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130]);
        }
        localFilePath = defaultFile.path;
      }
    }

    await db.transaction((txn) async {
      // 1. Atualizar Perfil no SQLite
      await txn.insert(
        DatabaseSchema.perfilTable,
        perfilValues,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Atualizar Assinatura no SQLite
      int sigLocalId;
      final existingSig = await txn.query(
        DatabaseSchema.assinaturaTable,
        columns: ['id_assinatura_local', 'id_assinatura', 'assinatura_json', 'sync_status'],
        where: 'id_proprietario = ?',
        whereArgs: [userId],
        limit: 1,
      );

      final signatureJsonData = {
        'id_proprietario': userId,
        'dados_assinatura': 'Assinatura de $nome',
        'formato': 'image',
        'data_assinatura': now,
        'caminho_ficheiro': localFilePath,
        'id_badges': badgeIdsDisposicao,
      };

      if (existingSig.isEmpty) {
        sigLocalId = await txn.insert(
          DatabaseSchema.assinaturaTable,
          {
            'id_proprietario': userId,
            'assinatura_json': jsonEncode(signatureJsonData),
            'update_assinatura': localFilePath,
            'local_updated_at': now,
            'sync_status': 'pending_insert',
          },
        );
      } else {
        final row = existingSig.first;
        sigLocalId = row['id_assinatura_local'] as int;
        final currentSync = row['sync_status'] as String;
        final newSyncStatus = currentSync == 'pending_insert' ? 'pending_insert' : 'pending_update';

        await txn.update(
          DatabaseSchema.assinaturaTable,
          {
            'assinatura_json': jsonEncode({
              ...signatureJsonData,
              'id_assinatura_local': sigLocalId,
              'id_assinatura': row['id_assinatura'],
            }),
            'update_assinatura': localFilePath,
            'local_updated_at': now,
            'sync_status': newSyncStatus,
          },
          where: 'id_assinatura_local = ?',
          whereArgs: [sigLocalId],
        );
      }

      // 3. Atualizar Badges da Assinatura
      await txn.delete(
        DatabaseSchema.badgesAssinaturaTable,
        where: 'id_assinatura_local = ?',
        whereArgs: [sigLocalId],
      );
      for (final badgeId in badgeIdsDisposicao) {
        await txn.insert(
          DatabaseSchema.badgesAssinaturaTable,
          {
            'id_assinatura_local': sigLocalId,
            'id_badge': badgeId,
          },
        );
      }

      // 4. Registrar Outbox de Perfil
      await txn.delete(
        DatabaseSchema.syncOutboxTable,
        where: "user_id = ? AND entity = 'perfil' AND local_record_id = ?",
        whereArgs: [userId, userId],
      );

      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'perfil',
        operation: 'update',
        localRecordId: userId,
        clientId: generateClientId(),
        payload: {
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'id_area': finalIdArea,
          'foto': fotoLocalPath,
        },
      );

      // 5. Registrar Outbox de Assinatura
      await txn.delete(
        DatabaseSchema.syncOutboxTable,
        where: "user_id = ? AND entity = 'assinatura' AND local_record_id = ?",
        whereArgs: [userId, sigLocalId],
      );

      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'assinatura',
        operation: existingSig.isEmpty ? 'insert' : 'update',
        localRecordId: sigLocalId,
        clientId: generateClientId(),
        payload: {
          'id_proprietario': userId,
          'caminho_ficheiro': localFilePath,
          'id_badges': badgeIdsDisposicao,
          'dados_assinatura': 'Assinatura de $nome',
          'formato': 'image',
          'data_assinatura': now,
        },
      );
    });

    // 6. Atualizar a cache local na memória
    await carregarDadosPerfil();
  }
}
