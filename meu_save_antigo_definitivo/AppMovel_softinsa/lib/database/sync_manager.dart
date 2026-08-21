import 'dart:io';
import 'package:flutter/foundation.dart';
import 'remote/api_client.dart';
import 'daos/sync_state_dao.dart';
import 'daos/areas_dao.dart';
import 'daos/badges_dao.dart';
import 'daos/perfil_dao.dart';
import 'daos/niveis_dao.dart';
import 'daos/requisitos_dao.dart';
import 'daos/objetivo_dao.dart';
import 'daos/submissao_dao.dart';
import 'daos/historico_dao.dart';
import 'daos/notificacao.dart';
import 'daos/permissoes_dao.dart';
import 'daos/badges_assinatura_dao.dart';
import 'daos/badges_requisitos_dao.dart';
import 'daos/submissao_requisitos_dao.dart';
import 'daos/outros_users_dao.dart';
import 'daos/learning_paths_dao.dart';
import 'daos/service_lines_dao.dart';
import 'daos/registo_badges.dart';
import 'daos/documentos_submissao_dao.dart';
import 'daos/assinaturas_dao.dart';
import 'daos/sync_outbox_dao.dart';
import 'database_helper.dart';
import 'database_schema.dart';
import 'sync_helpers.dart';
import 'dart:convert';

class SyncManager {
  static final SyncManager instance = SyncManager();

  final ApiClient _api = ApiClient();
  final SyncStateDao _syncStateDao = SyncStateDao();

  final AreasDao _areasDao = AreasDao.instance;
  final BadgesDao _badgesDao = BadgesDao.instance;
  final PerfilDao _perfilDao = PerfilDao.instance;
  final NiveisDao _niveisDao = NiveisDao.instance;
  final RequisitosDao _requisitosDao = RequisitosDao.instance;
  final ObjetivosDao _objetivoDao = ObjetivosDao.instance;
  final SubmissoesDao _submissoesDao = SubmissoesDao.instance;
  final HistoricoDao _historicoDao = HistoricoDao.instance;
  final NotificacoesDao _notificacaoDao = NotificacoesDao.instance;
  final PermissoesDao _permissoesDao = PermissoesDao.instance;
  final BadgesAssinaturaDao _badgesAssinaturaDao = BadgesAssinaturaDao.instance;
  final OutrosUsersDao _outrosUsersDao = OutrosUsersDao.instance;

  final LearningPathsDao _learningPathsDao = LearningPathsDao.instance;
  final ServiceLinesDao _serviceLinesDao = ServiceLinesDao.instance;
  final RegistoBadgesDao _registoBadgesDao = RegistoBadgesDao.instance;
  final DocumentosSubmissaoDao _documentosDao = DocumentosSubmissaoDao.instance;
  final AssinaturasDao _assinaturasDao = AssinaturasDao.instance;
  final BadgesRequisitosDao _badgesRequisitosDao = BadgesRequisitosDao.instance;
  final SubmissaoRequisitosDao _submissaoRequisitosDao = SubmissaoRequisitosDao.instance;

  /// ==========================================
  /// CICLO COMPLETO (PUSH ANTES DE PULL)
  /// ==========================================
  Future<void> syncAll(int userId) async {
    print('🔄 [SyncManager] A iniciar ciclo completo de sincronização...');
    await executePushSync(userId); // 1º Envia alterações locais pendentes
    await executePullSync(userId); // 2º Descarrega atualizações do servidor
  }

  /// ==========================================
  /// UPLOAD DE DADOS (PUSH SYNC)
  /// ==========================================
  Future<bool> executePushSync(int userId) async {
    debugPrint('🔄 [SyncManager] A iniciar Push Sync...');
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> pending = [];

    String normalizeEntity(String entity) {
      switch (entity.toLowerCase()) {
        case 'submission': case 'submissao': case 'candidaturas': case 'candidatura': return 'submissoes';
        case 'objective': case 'objetivo': return 'objetivos';
        case 'document': case 'documento': return 'documentos_submissao';
        case 'notification': case 'notificacao': return 'notificacoes';
        case 'profile': case 'perfil': return 'perfil';
        case 'user_badges': case 'registo_badges': return 'registo_badges';
        case 'signature': case 'assinatura': case 'assinaturas': return 'assinatura';
        default: return entity;
      }
    }

    try {
      // 1. Processar primeiro os uploads físicos dos documentos pendentes
      await _processPendingDocumentUploads(userId);
      // 1.2 Processar os uploads de fotos de perfil pendentes
      await _processPendingProfilePhotoUploads(userId);
      // 1.3 Pré-upload de fotos de perfil e assinaturas locais na Outbox (conversão para URLs HTTPS)
      await _preUploadFiles(userId);

      pending = await SyncOutboxDao.instance.lerPendentes(userId);
      debugPrint('🔍 [DEBUG 1] Pendentes na Outbox: ${pending.length} itens');
      if (pending.isEmpty) {
        debugPrint('✅ [SyncManager] Sem registos pendentes no Outbox.');
        return true;
      }

      debugPrint('📦 [SyncManager] Encontrados ${pending.length} registos pendentes no Outbox.');

      final List<Map<String, dynamic>> operations = [];
      for (final row in pending) {
        final String rawEntity = row['entity'] as String? ?? '';
        final String entity = normalizeEntity(rawEntity);

        if (entity == 'documentos_submissao' || (entity == 'perfil' && row['operation'] == 'update_foto')) continue;

        if (entity == 'last_login') {
          debugPrint('🔄 [SyncManager] A sincronizar last_login para o utilizador $userId...');
          final success = await _api.atualizarLastLogin(userId);
          await SyncOutboxDao.instance.marcarComoConcluida(row['id'] as String);
          if (success) {
            debugPrint('✅ [SyncManager] last_login sincronizado com sucesso.');
          } else {
            debugPrint('⚠️ [SyncManager] last_login registado localmente.');
          }
          continue;
        }

        // Guarda: se a operação de perfil 'update' ainda tiver um caminho de foto local
        // (não-HTTPS), significa que o pré-upload para Cloudinary falhou ou ainda não ocorreu.
        // Neste caso, ignoramos esta operação neste ciclo de sync para evitar enviar um
        // caminho local inválido ao servidor.
        if (entity == 'perfil' && row['operation'] == 'update') {
          try {
            final rawPayload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
            final fotoField = rawPayload['foto']?.toString() ?? '';
            if (fotoField.isNotEmpty && !fotoField.startsWith('http')) {
              debugPrint('⏭️ [SyncManager] Perfil update ignorado neste ciclo: foto ainda é caminho local ($fotoField). A aguardar upload Cloudinary.');
              continue;
            }
          } catch (_) {}
        }

        final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        
        // Se for submissão, garantir que enviamos o ID remoto real do Postgres se já resolvido localmente
        if (entity == 'submissoes') {
          final localId = row['local_record_id'] as int?;
          if (localId != null && payload['id_submissao'] == null) {
            final subRows = await db.query(
              DatabaseSchema.submissoesTable,
              columns: ['id_submissao'],
              where: 'id_submissao_local = ?',
              whereArgs: [localId],
              limit: 1,
            );
            if (subRows.isNotEmpty && subRows.first['id_submissao'] != null) {
              payload['id_submissao'] = intOrNull(subRows.first['id_submissao']);
            }
          }
        }

        operations.add({
          'id': row['id'],
          'user_id': row['user_id'],
          'entity': entity,
          'operation': row['operation'],
          'local_record_id': row['local_record_id'],
          'client_id': row['client_id'],
          'payload': payload,
          'created_at': row['created_at'],
        });
      }

      // Ordenar operações: submissoes vêm primeiro para garantir que a FK de documentos_submissao seja satisfeita no backend
      operations.sort((a, b) {
        final aEntity = a['entity'] as String? ?? '';
        final bEntity = b['entity'] as String? ?? '';
        if (aEntity == 'submissoes' && bEntity != 'submissoes') return -1;
        if (aEntity != 'submissoes' && bEntity == 'submissoes') return 1;
        return 0;
      });

      bool pushSuccess = true;

      if (operations.isNotEmpty) {
        final payloadBatch = {'operations': operations};
        debugPrint('🌐 [AUDIT] POST URL: https://pint-he77.onrender.com/api/mobile/push');
        debugPrint('📦 [AUDIT] Payload JSON Enviado: ${jsonEncode(payloadBatch)}');
        
        final response = await _api.pushSync(payloadBatch);
        debugPrint('🌐 [AUDIT] Resposta Completa do Servidor: ${jsonEncode(response)}');

        if (response != null && response['success'] == true) {
          final processedIds = response['processed_ids'] as Map<String, dynamic>? ?? {};
          debugPrint('📦 [AUDIT] processed_ids de todas as entidades: ${jsonEncode(processedIds)}');

          if (processedIds.containsKey('submissoes')) {
            final valSub = processedIds['submissoes'];
            debugPrint('📦 [AUDIT] processed_ids["submissoes"] raw: $valSub');
            debugPrint('📦 [AUDIT] processed_ids["submissoes"] tipo: ${valSub.runtimeType}');
            if (valSub is Map) {
              for (final entry in valSub.entries) {
                debugPrint('🔑 [AUDIT] Submissao Entry - Chave: "${entry.key}" (tipo: ${entry.key.runtimeType}), Valor: "${entry.value}" (tipo: ${entry.value.runtimeType})');
              }
            }
          }

          if (processedIds.containsKey('assinatura') || processedIds.containsKey('assinaturas')) {
            final mapaAssinaturas = processedIds['assinatura'] ?? processedIds['assinaturas'];
            if (mapaAssinaturas is Map && mapaAssinaturas.isNotEmpty) {
              await _assinaturasDao.confirmarSincronizacaoEmLote(mapaAssinaturas);
            }
          }

          await db.transaction((txn) async {
            // 1. Atualizar IDs locais com IDs do servidor nas tabelas de dados
            for (final entry in processedIds.entries) {
              final String rawEntityName = entry.key;
              final String entityName = normalizeEntity(rawEntityName);
              final val = entry.value;

              if (val is Map) {
                // Caso submissoes, processa o mapa de id_local para id_servidor
                for (final mapEntry in val.entries) {
                  final idLocal = intOrNull(mapEntry.key);
                  final idServidor = intOrNull(mapEntry.value);
                  debugPrint('🔗 [AUDIT Reconcile] Tentando reconciliar $entityName - idLocal: $idLocal, idServidor: $idServidor');
                  if (idLocal != null && idServidor != null) {
                    if (entityName == 'submissoes') {
                      await _submissoesDao.reconciliarIdServidor(idLocal, idServidor, txn);
                    }
                  }
                }
              } else if (val is List) {
                for (final pair in val) {
                  if (pair is Map) {
                    final idLocal = intOrNull(pair['id_local']);
                    final idServidor = intOrNull(pair['id_servidor']);

                    if (idLocal != null && idServidor != null) {
                      if (entityName == 'submissoes') {
                        await _submissoesDao.reconciliarIdServidor(idLocal, idServidor, txn);
                      } else if (entityName == 'objetivos') {
                        await _objetivoDao.marcarComoSincronizado(idLocal, idServidor, txn);
                      } else if (entityName == 'notificacoes') {
                        await _notificacaoDao.marcarComoSincronizado(idLocal, idServidor, txn);
                      } else if (entityName == 'perfil') {
                        await _perfilDao.marcarComoSincronizado(idLocal, idServidor, txn);
                      } else if (entityName == 'registo_badges') {
                        await _registoBadgesDao.marcarComoSincronizado(idLocal, idServidor, txn);
                      }
                    }
                  }
                }
              }
            }

            // 2. Marcar apenas as operações estruturais enviadas como concluídas
            for (final op in operations) {
              await txn.update(
                DatabaseSchema.syncOutboxTable,
                {'status': 'completed'},
                where: 'id = ?',
                whereArgs: [op['id']],
              );
            }
          });
        } else {
          pushSuccess = false;
        }
      }

      if (pushSuccess) {
        debugPrint('✅ [SyncManager] Push Sync concluído com sucesso!');
        return true;
      }
    } catch (e, stack) {
      debugPrint('💥 [ERRO PUSH]: $e');
      debugPrint('💥 [STACK TRACE]: $stack');
      
      // Incrementa as tentativas no outbox se falhar
      try {
        final outboxBatch = db.batch();
        for (final row in pending) {
          final currentAttempts = (row['attempts'] as int?) ?? 0;
          outboxBatch.update(
            DatabaseSchema.syncOutboxTable,
            {
              'attempts': currentAttempts + 1,
              'status': 'pending',
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        await outboxBatch.commit(noResult: true);
      } catch (err) {
        debugPrint('❌ [SyncManager] Erro ao incrementar tentativas do Outbox: $err');
      }
    }
    return false;
  }

  /// Método auxiliar privado para processar os uploads dos documentos (evidências)
  /// e fazer o envio dos ficheiros físicos um por um utilizando multipart.
  Future<void> _processPendingDocumentUploads(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final pendingDocs = await db.query(
      DatabaseSchema.syncOutboxTable,
      where: 'user_id = ? AND entity = ? AND status = ?',
      whereArgs: [userId, 'documentos_submissao', 'pending'],
    );

    debugPrint('📤 [SyncManager] Encontrados ${pendingDocs.length} documentos pendentes para upload.');

    for (final row in pendingDocs) {
      try {
        final payload = jsonDecode(row['payload'] as String);
        final int? idSubLocal = intOrNull(payload['id_submissao_local']);
        final int? reqId = intOrNull(payload['id_requisito']);
        final String? localPath = payload['url_ficheiro'] as String?;
        final int localDocId = row['local_record_id'] as int;

        if (idSubLocal == null || reqId == null || localPath == null) {
          await db.update(
            DatabaseSchema.syncOutboxTable,
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          continue;
        }

        final file = File(localPath);
        if (!await file.exists()) {
          debugPrint('⚠️ [SyncManager] Ficheiro não encontrado localmente: $localPath. A ignorar upload.');
          await db.update(
            DatabaseSchema.syncOutboxTable,
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          continue;
        }

        // Tentar obter o ID remoto da submissão para onde associar o ficheiro
        int? remoteSubId = intOrNull(payload['id_submissao']);
        if (remoteSubId == null) {
          final subRows = await db.query(
            DatabaseSchema.submissoesTable,
            columns: ['id_submissao'],
            where: 'id_submissao_local = ?',
            whereArgs: [idSubLocal],
            limit: 1,
          );
          if (subRows.isNotEmpty && subRows.first['id_submissao'] != null) {
            remoteSubId = intOrNull(subRows.first['id_submissao']);
          }
        }

        if (remoteSubId == null) {
          debugPrint('⚠️ [SyncManager] Submissão local $idSubLocal ainda não tem ID do servidor. Adiado.');
          continue;
        }

        debugPrint('📤 [SyncManager] A carregar ficheiro para o servidor: $localPath');
        final uploadRes = await _api.uploadDocument(localPath, {
          'id_submissao': remoteSubId,
          'id_requisito': reqId,
        });

        if (uploadRes != null && (uploadRes['success'] == true || uploadRes['id'] != null)) {
          final int? remoteFileId = intOrNull(uploadRes['id'] ?? uploadRes['id_ficheiro']);
          if (remoteFileId != null) {
            await _documentosDao.marcarComoSincronizado(localDocId, remoteFileId);
          }
          await db.update(
            DatabaseSchema.syncOutboxTable,
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          debugPrint('✅ [SyncManager] Upload de evidência $localDocId concluído com sucesso!');
        } else {
          debugPrint('❌ [SyncManager] Falha no upload de evidência $localDocId');
        }
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Erro ao processar upload do documento da outbox: $e');
      }
    }
  }

  /// ==========================================
  /// DOWNLOAD DE DADOS (PULL SYNC)
  /// ==========================================
  Future<bool> executePullSync([int? userId]) async {
    print('🔄 [SyncManager] A iniciar Pull Sync...');

    try {
      int? activeUserId = userId;
      if (activeUserId == null) {
        try {
          final db = await DatabaseHelper.instance.database;
          final rows = await db.query(
            DatabaseSchema.perfilTable,
            columns: ['id_utilizador'],
            limit: 1,
          );
          if (rows.isNotEmpty) {
            activeUserId = intOrNull(rows.first['id_utilizador']);
          }
        } catch (_) {}
      }

      if (activeUserId == null) {
        print('⚠️ [SyncManager] Cancelado: Nenhum utilizador autenticado encontrado para sincronizar.');
        return false;
      }

      final String? lastSync = await _syncStateDao.getCursor(activeUserId, 'global_sync');
      final response = await _api.pullSync(since: lastSync);

      if (response != null && response['success'] == true) {
        final data = response['data'] ?? {};
        final deleted = response['deleted'] ?? {};
        
        print('📦 RESUMO DOS DADOS RECEBIDOS:');
        data.forEach((chave, valor) {
          if (valor is List) {
            print('   ➡️ $chave: ${valor.length} registos');
          } else if (valor is Map) {
            print('   ➡️ $chave: 1 registo (Objeto único)');
          } else {
            print('   ➡️ $chave: Vazio');
          }
        });

        print('✅ Dados recebidos! A gravar no SQLite por ordem de dependência...');

        // 1º Tabelas Base (niveis, service_lines, areas, learning_paths, requisitos, permissoes, assinaturas)
        if (data['learning_paths'] != null) {
          await _learningPathsDao.upsertFromSync(_safeList(data['learning_paths']));
        }
        if (data['niveis'] != null) {
          await _niveisDao.upsertFromSync(_safeList(data['niveis']));
        }
        if (data['service_lines'] != null) {
          await _serviceLinesDao.upsertFromSync(_safeList(data['service_lines']));
        }
        if (data['areas'] != null) {
          await _areasDao.upsertFromSync(_safeList(data['areas']));
        }
        if (data['requisitos'] != null) {
          await _requisitosDao.upsertFromSync(_safeList(data['requisitos']));
        }
        if (data['permissoes'] != null) {
          await _permissoesDao.upsertFromSync(_safeList(data['permissoes']));
        }
        if (data['assinatura'] != null) {
          await _assinaturasDao.upsertFromSync(_safeList(data['assinatura']));
        }
        if (data['outros_users'] != null) {
          await _outrosUsersDao.upsertFromSync(_safeList(data['outros_users']));
        }

        // 2º Entidades Principais (perfil, badges, submissoes, objetivos)
        if (data['perfil'] != null) {
          await _perfilDao.upsertFromSync(_safeList(data['perfil']));
        }
        if (data['badges'] != null) {
          await _badgesDao.upsertFromSync(_safeList(data['badges']));
        }
        if (data['submissoes'] != null) {
          await _submissoesDao.upsertFromSync(_safeList(data['submissoes']));
        }
        if (data['objetivos'] != null) {
          await _objetivoDao.upsertFromSync(_safeList(data['objetivos']));
        }

        // 3º Entidades Dependentes e Relações (badges_requisitos, badges_assinatura, submissao_requisitos, registos_badges, notificacoes, historico, documentos)
        if (data['badges_requisitos'] != null || data['requisitos_badges'] != null) {
          final badgesReqs = data['badges_requisitos'] ?? data['requisitos_badges'];
          await _badgesRequisitosDao.upsertFromSync(_safeList(badgesReqs));
        }
        if (data['badges_assinatura'] != null) {
          await _badgesAssinaturaDao.upsertFromSync(_safeList(data['badges_assinatura']));
        }
        if (data['submissao_requisitos'] != null) {
          await _submissaoRequisitosDao.upsertFromSync(_safeList(data['submissao_requisitos']));
        }
        if (data['registos_badges'] != null) { 
          await _registoBadgesDao.upsertFromSync(_safeList(data['registos_badges']));
        }
        if (data['notificacoes'] != null) {
          await _notificacaoDao.upsertFromSync(_safeList(data['notificacoes']));
        }
        if (data['historico'] != null) {
          await _historicoDao.upsertFromSync(_safeList(data['historico']));
        }
        if (data['documentos'] != null) {
          await _documentosDao.upsertFromSync(_safeList(data['documentos']));
        }

        print('🗑️ A processar eliminações...');

        // Eliminações via chave 'deleted' de nível global
        if (deleted['objetivos'] != null) {
          for (var id in deleted['objetivos']) {
            final intId = int.tryParse(id.toString());
            if (intId != null) await _objetivoDao.apagarFisicamente(intId);
          }
        }
        if (deleted['submissoes'] != null) {
          for (var id in deleted['submissoes']) {
            final intId = int.tryParse(id.toString());
            if (intId != null) await _submissoesDao.apagarFisicamente(intId);
          }
        }

        // Eliminações via envelope delta { "deleted": [...] } dentro de data['notificacoes']
        if (data['notificacoes'] is Map &&
            (data['notificacoes'] as Map).containsKey('deleted')) {
          final deletedItems = (data['notificacoes'] as Map)['deleted'];
          if (deletedItems is List && deletedItems.isNotEmpty) {
            final deletedIds = deletedItems
                .map((item) => item is Map
                    ? int.tryParse((item['id_notificacao'] ?? item['id'] ?? '').toString())
                    : int.tryParse(item.toString()))
                .whereType<int>()
                .toList();
            if (deletedIds.isNotEmpty) {
              print('🗑️ [SyncManager] A eliminar ${deletedIds.length} notificação(ões): $deletedIds');
              await _notificacaoDao.deleteByIds(deletedIds);
            }
          }
        }

        final novoCursor = response['sync_until'] ?? DateTime.now().toUtc().toIso8601String();
        await _syncStateDao.updateCursor(activeUserId, 'global_sync', novoCursor);
        
        print('🎉 Pull Sync totalmente concluído e TODA a base de dados preenchida!');
        return true;
      }
    } catch (e) {
      print('❌ [SyncManager] Falha no Pull Sync: $e');
    }
    return false;
  }

  List<Map<String, dynamic>> _safeList(dynamic input) {
    if (input == null) return [];

    if (input is Map) {
      // Caso 1: Envelope Delta com chave 'upserts' — extrai apenas os upserts
      if (input.containsKey('upserts') && input['upserts'] is List) {
        return List<Map<String, dynamic>>.from(input['upserts']);
      }

      // Caso 2: Objeto único com ID válido — envolve como registo singular
      final hasValidId = input.keys.any((k) => 
        k.toString().toLowerCase() == 'id' || 
        k.toString().toLowerCase().startsWith('id_') || 
        k.toString().toLowerCase().endsWith('_id')
      );
      if (hasValidId) {
        return [Map<String, dynamic>.from(input)];
      }

      // Caso 3: Envelope de eliminações puro ex: { "deleted": [...] } — não inserir nada
      return [];
    }

    if (input is List) {
      return List<Map<String, dynamic>>.from(input);
    }

    return [];
  }

  Future<Map<String, dynamic>?> uploadEvidence(String filePath, Map<String, dynamic> additionalFields) async {
    return await _api.uploadDocument(filePath, additionalFields);
  }

  Future<void> _processPendingProfilePhotoUploads(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final pendingPhotos = await db.query(
      DatabaseSchema.syncOutboxTable,
      where: "user_id = ? AND entity = 'perfil' AND operation = 'update_foto' AND status = ?",
      whereArgs: [userId, 'pending'],
    );

    debugPrint('📤 [SyncManager] Encontrados ${pendingPhotos.length} uploads de fotos de perfil pendentes.');

    for (final row in pendingPhotos) {
      try {
        final payload = jsonDecode(row['payload'] as String);
        final String? localPath = payload['local_path'] as String?;
        if (localPath == null) {
          await db.update(
            DatabaseSchema.syncOutboxTable,
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          continue;
        }

        final file = File(localPath);
        if (!await file.exists()) {
          debugPrint('⚠️ [SyncManager] Foto local não encontrada: $localPath. A ignorar.');
          await db.update(
            DatabaseSchema.syncOutboxTable,
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          continue;
        }

        debugPrint('📤 [SyncManager] A fazer upload da foto de perfil para o servidor: $localPath');
        final secureUrl = await _api.uploadProfilePhotoOffline(userId, localPath);

        if (secureUrl != null && secureUrl.isNotEmpty) {
          // Atualiza o URL remoto na tabela 'perfil' local
          await db.update(
            DatabaseSchema.perfilTable,
            {
              'imagem_perfil': secureUrl,
              'sync_status': 'synced',
            },
            where: 'id_utilizador = ?',
            whereArgs: [userId],
          );

          // Marca a linha do Outbox como concluída
          await db.update(
            DatabaseSchema.syncOutboxTable,
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [row['id']],
          );

          debugPrint('✅ [SyncManager] Foto de perfil enviada e atualizada no SQLite com sucesso: $secureUrl');
        } else {
          debugPrint('❌ [SyncManager] Falha no upload da foto de perfil.');
        }
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Erro ao processar upload de foto de perfil da outbox: $e');
      }
    }
  }

  Future<void> _preUploadFiles(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final pending = await SyncOutboxDao.instance.lerPendentes(userId);

    for (final row in pending) {
      final String id = row['id'] as String;
      final String rawEntity = row['entity'] as String? ?? '';
      final String entity = rawEntity.toLowerCase();
      final operation = row['operation'] as String? ?? '';

      if (entity == 'perfil' && (operation == 'update' || operation == 'update_foto')) {
        try {
          final payload = Map<String, dynamic>.from(jsonDecode(row['payload'] as String));
          final String? localPath = payload['foto'] as String? ?? payload['local_path'] as String?;

          if (localPath != null && localPath.isNotEmpty && !localPath.startsWith('http')) {
            final file = File(localPath);
            if (!await file.exists()) {
              debugPrint('⚠️ [SyncManager Pre-Upload] Ficheiro de foto de perfil não encontrado no disco: $localPath');
              // Limpa o campo para não bloquear o sync do resto do perfil
              payload['foto'] = null;
              await db.update(
                DatabaseSchema.syncOutboxTable,
                {'payload': jsonEncode(payload)},
                where: 'id = ?',
                whereArgs: [id],
              );
              continue;
            }

            debugPrint('📤 [SyncManager Pre-Upload] A fazer upload da foto de perfil: $localPath');
            final secureUrl = await _api.uploadProfilePhotoOffline(userId, localPath);

            if (secureUrl != null && secureUrl.isNotEmpty) {
              // Substitui caminho local pela URL Cloudinary no payload
              payload['foto'] = secureUrl;
              payload['local_path'] = secureUrl;

              await db.update(
                DatabaseSchema.syncOutboxTable,
                {'payload': jsonEncode(payload)},
                where: 'id = ?',
                whereArgs: [id],
              );

              // Atualiza a coluna 'imagem_perfil' no SQLite com o URL remoto
              await db.update(
                DatabaseSchema.perfilTable,
                {
                  'imagem_perfil': secureUrl,
                  'sync_status': 'pending_update',
                },
                where: 'id_utilizador = ?',
                whereArgs: [userId],
              );
              debugPrint('✅ [SyncManager Pre-Upload] Foto de perfil enviada com sucesso: $secureUrl');
            } else {
              debugPrint('❌ [SyncManager Pre-Upload] Falha no upload da foto de perfil. Payload com caminho local NÃO será enviado ao servidor neste ciclo.');
              // Não alteramos o payload — a guarda no loop de operations vai bloquear o envio
            }
          }
        } catch (e) {
          debugPrint('⚠️ [SyncManager Pre-Upload] Erro no pré-upload da foto de perfil: $e');
        }
      }

      if (entity == 'assinatura' && (operation == 'update' || operation == 'insert')) {
        try {
          final payload = Map<String, dynamic>.from(jsonDecode(row['payload'] as String));
          final String? localPath = payload['caminho_ficheiro'] as String?;

          if (localPath != null && localPath.isNotEmpty && !localPath.startsWith('http')) {
            final file = File(localPath);
            if (await file.exists()) {
              debugPrint('📤 [SyncManager Pre-Upload] A fazer upload da assinatura: $localPath');
              final res = await _api.uploadDocument(localPath);
              final String? secureUrl = (res?['url'] ?? res?['url_ficheiro'] ?? res?['data']?['url'])?.toString();

              if (secureUrl != null && secureUrl.isNotEmpty) {
                // Substitui no payload
                payload['caminho_ficheiro'] = secureUrl;

                await db.update(
                  DatabaseSchema.syncOutboxTable,
                  {'payload': jsonEncode(payload)},
                  where: 'id = ?',
                  whereArgs: [id],
                );

                // Atualiza a tabela 'assinaturas' no SQLite
                final sigLocalId = row['local_record_id'] as int;
                final existingSig = await db.query(
                  DatabaseSchema.assinaturaTable,
                  where: 'id_assinatura_local = ?',
                  whereArgs: [sigLocalId],
                  limit: 1,
                );

                if (existingSig.isNotEmpty) {
                  final rowSig = existingSig.first;
                  Map<String, dynamic> sigJson = {};
                  try {
                    sigJson = Map<String, dynamic>.from(jsonDecode(rowSig['assinatura_json'] as String? ?? '{}'));
                  } catch (_) {}

                  sigJson['caminho_ficheiro'] = secureUrl;

                  await db.update(
                    DatabaseSchema.assinaturaTable,
                    {
                      'update_assinatura': secureUrl,
                      'assinatura_json': jsonEncode(sigJson),
                      'sync_status': 'synced',
                    },
                    where: 'id_assinatura_local = ?',
                    whereArgs: [sigLocalId],
                  );
                }
                debugPrint('✅ [SyncManager Pre-Upload] Assinatura enviada com sucesso: $secureUrl');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [SyncManager Pre-Upload] Erro no pré-upload da assinatura: $e');
        }
      }
    }
  }
}