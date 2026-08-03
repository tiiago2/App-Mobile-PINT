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
    print('🔄 [SyncManager] A iniciar Push Sync...');
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> pending = [];

    String normalizeEntity(String entity) {
      switch (entity.toLowerCase()) {
        case 'submission': case 'submissao': return 'submissoes';
        case 'objective': case 'objetivo': return 'objetivos';
        case 'document': case 'documento': return 'documentos_submissao';
        case 'notification': case 'notificacao': return 'notificacoes';
        case 'profile': case 'perfil': return 'perfil';
        case 'user_badges': case 'registo_badges': return 'registo_badges';
        default: return entity;
      }
    }

    try {
      pending = await SyncOutboxDao.instance.lerPendentes(userId);
      print('🔍 [DEBUG 1] Pendentes na Outbox: ${pending.length} itens');
      if (pending.isEmpty) {
        print('✅ [SyncManager] Sem registos pendentes no Outbox.');
        return true;
      }

      print('📦 [SyncManager] Encontrados ${pending.length} registos pendentes no Outbox.');

      final List<Map<String, dynamic>> operations = [];
      for (final row in pending) {
        final String rawEntity = row['entity'] as String? ?? '';
        final String entity = normalizeEntity(rawEntity);

        operations.add({
          'id': row['id'],
          'user_id': row['user_id'],
          'entity': entity,
          'operation': row['operation'],
          'local_record_id': row['local_record_id'],
          'client_id': row['client_id'],
          'payload': jsonDecode(row['payload'] as String),
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

      // Pré-resolução dinâmica de IDs do servidor para documentos_submissao
      for (var op in operations) {
        if (op['entity'] == 'documentos_submissao') {
          final payload = op['payload'];
          if (payload is Map<String, dynamic>) {
            final int? idSubLocal = intOrNull(payload['id_submissao_local']);
            if (idSubLocal != null && payload['id_submissao'] == null) {
              final subList = await db.query(
                DatabaseSchema.submissoesTable,
                where: 'id_submissao_local = ?',
                whereArgs: [idSubLocal],
              );
              if (subList.isNotEmpty) {
                final int? idServidorReal = intOrNull(
                  subList.first['id_submissao'] ??
                  subList.first['id_servidor'] ??
                  subList.first['id_submissao_servidor']
                );
                if (idServidorReal != null) {
                  payload['id_submissao'] = idServidorReal;
                  print('🔗 [SyncManager] Documento para submissão local $idSubLocal associado ao ID Servidor $idServidorReal antes do envio!');
                }
              }
            }
          }
        }
      }

      final payloadBatch = {'operations': operations};
      print('📦 [DEBUG 2] Payload Enviado: ${jsonEncode(payloadBatch)}');
      
      final response = await _api.pushSync(payloadBatch);
      print('🌐 [DEBUG 3] Resposta do Servidor: $response');

      if (response != null && response['success'] == true) {
        final processedIds = response['processed_ids'] as Map<String, dynamic>? ?? {};

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
            final list = entry.value;

            if (list is List) {
              for (final pair in list) {
                if (pair is Map) {
                  final idLocal = intOrNull(pair['id_local']);
                  final idServidor = intOrNull(pair['id_servidor']);

                  if (idLocal != null && idServidor != null) {
                    if (entityName == 'submissoes') {
                      await _submissoesDao.marcarComoSincronizado(idLocal, idServidor, txn);
                    } else if (entityName == 'documentos_submissao') {
                      await _documentosDao.marcarComoSincronizado(idLocal, idServidor, txn);
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

          // 2. Marcar operações pendentes na outbox como concluídas
          for (final row in pending) {
            await txn.update(
              DatabaseSchema.syncOutboxTable,
              {'status': 'completed'},
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
        });

        print('✅ [SyncManager] Push Sync concluído com sucesso!');
        return true;
      }
    } catch (e, stack) {
      print('💥 [ERRO PUSH]: $e');
      print('💥 [STACK TRACE]: $stack');
      
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
        print('❌ [SyncManager] Erro ao incrementar tentativas do Outbox: $err');
      }
    }
    return false;
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
}