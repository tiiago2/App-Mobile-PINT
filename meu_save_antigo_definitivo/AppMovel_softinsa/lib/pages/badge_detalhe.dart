import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../database/daos/requisitos_dao.dart';
import '../database/daos/submissao_dao.dart';
import '../database/sync_manager.dart';
import '../database/database_helper.dart';
import '../database/database_schema.dart';
import '../database/remote/api_client.dart';
import '../controllers/auth_controller.dart';
import '../database/sync_helpers.dart';

/// Ecrã de detalhe de um badge.
///
/// Carrega os requisitos reais do badge a partir do SQLite e avalia se cada
/// um deles foi cumprido pelo utilizador através de consultas à base de dados.
class BadgeDetalheScreen extends StatefulWidget {
  final Map<String, dynamic> badge;

  const BadgeDetalheScreen({super.key, required this.badge});

  @override
  State<BadgeDetalheScreen> createState() => _BadgeDetalheScreenState();
}

class _BadgeDetalheScreenState extends State<BadgeDetalheScreen> {
  List<Map<String, dynamic>> _requisitos = [];
  bool _loadingRequisitos = true;
  String? _feedbackRejeicao;
  String? _dataExpiracao;
  int? _submissaoLocalId;
  Map<int, Map<String, dynamic>> _requisitoDocumentos = {};

  @override
  void initState() {
    super.initState();
    _carregarRequisitos();
  }

  Future<void> _carregarRequisitos() async {
    try {
      final userId = int.tryParse(AuthController.instance.currentUser?['id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['user_id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['id_utilizador']?.toString() ?? '') ??
          1;

      // Resolução defensiva do id_badge
      var badgeId = int.tryParse(widget.badge['id_badge']?.toString() ?? '') ??
          int.tryParse(widget.badge['id']?.toString() ?? '');

      if (badgeId == null) {
        final titulo = (widget.badge['titulo'] ?? widget.badge['nome_badge'] ?? widget.badge['title'] ?? '').toString();
        if (titulo.isNotEmpty) {
          badgeId = await RequisitosDao.instance.obterIdBadgePorNome(titulo);
        }
      }

      String? feedback;
      String? dataExpiracao;

      if (badgeId != null) {
        final db = await DatabaseHelper.instance.database;
        final estado = _estadoNormalizado;

        // ── Feedback de rejeição ────────────────────────────────────────────
        // Passo 1: encontrar a submissão rejeitada do utilizador para este badge
        // Passo 2a: procurar em historico_candidatura (via id remoto)
        // Passo 2b: fallback — procurar feedback embutido em submissao_json
        if (estado.contains('recusado') || estado.contains('rejeit')) {
          final submissaoRows = await db.rawQuery('''
            SELECT id_submissao, id_submissao_local, submissao_json
            FROM ${DatabaseSchema.submissoesTable}
            WHERE id_utilizador = ? AND id_badge = ?
              AND LOWER(TRIM(status)) IN (
                'rejeitado','rejeitada','reprovado','reprovada',
                'recusado','recusada','rejected'
              )
              AND (deleted_submissao IS NOT 1)
            ORDER BY id_submissao_local DESC
            LIMIT 1
          ''', [userId, badgeId]);

          if (submissaoRows.isNotEmpty) {
            final idSubmissaoRemoto = submissaoRows.first['id_submissao'];
            final idSubmissaoLocal  = submissaoRows.first['id_submissao_local'];
            final submissaoJsonStr  = submissaoRows.first['submissao_json'] as String?;

            // 2a: historico_candidatura pelo id remoto
            if (idSubmissaoRemoto != null) {
              final histRows = await db.rawQuery('''
                SELECT feedback
                FROM ${DatabaseSchema.historicoTable}
                WHERE id_submissao = ?
                  AND aceite = 0
                  AND feedback IS NOT NULL
                  AND (deleted_historico IS NOT 1)
                ORDER BY data_avaliacao DESC
                LIMIT 1
              ''', [idSubmissaoRemoto]);
              if (histRows.isNotEmpty) {
                feedback = histRows.first['feedback'] as String?;
              }
            }

            // 2a fallback: historico_candidatura pelo id local
            if ((feedback == null || feedback.isEmpty) && idSubmissaoLocal != null) {
              final histRows2 = await db.rawQuery('''
                SELECT feedback
                FROM ${DatabaseSchema.historicoTable}
                WHERE id_submissao = ?
                  AND aceite = 0
                  AND feedback IS NOT NULL
                  AND (deleted_historico IS NOT 1)
                ORDER BY data_avaliacao DESC
                LIMIT 1
              ''', [idSubmissaoLocal]);
              if (histRows2.isNotEmpty) {
                feedback = histRows2.first['feedback'] as String?;
              }
            }

            // 2b: fallback — extrair feedback do submissao_json guardado
            if ((feedback == null || feedback.isEmpty) && submissaoJsonStr != null) {
              try {
                final jsonMap = jsonDecode(submissaoJsonStr);
                if (jsonMap is Map) {
                  // Feedback directo no topo do JSON
                  final directFeedback = jsonMap['feedback']?.toString();
                  if (directFeedback != null && directFeedback.isNotEmpty) {
                    feedback = directFeedback;
                  }
                  // Feedback dentro de lista 'historico'
                  if ((feedback == null || feedback.isEmpty)) {
                    final hist = jsonMap['historico'];
                    if (hist is List && hist.isNotEmpty) {
                      for (final entry in hist) {
                        if (entry is Map) {
                          final aceite = entry['aceite'];
                          final isRejected = aceite == 0 || aceite == false || aceite == '0';
                          final fb = entry['feedback']?.toString();
                          if (isRejected && fb != null && fb.isNotEmpty) {
                            feedback = fb;
                            break;
                          }
                        }
                      }
                    }
                  }
                }
              } catch (_) {
                // JSON inválido — ignorar
              }
            }

            // 2c: fallback final — buscar historico directamente à API
            // (a API não inclui historico no pull sync global)
            if ((feedback == null || feedback.isEmpty) && idSubmissaoRemoto != null) {
              try {
                final remoteId = idSubmissaoRemoto is int
                    ? idSubmissaoRemoto
                    : int.tryParse(idSubmissaoRemoto.toString());
                if (remoteId != null) {
                  final hist = await ApiClient().fetchHistoricoSubmissao(remoteId);
                  if (hist != null && hist.isNotEmpty) {
                    // Guardar na tabela local para futuros acessos
                    for (final entry in hist) {
                      try {
                        await db.insert(
                          DatabaseSchema.historicoTable,
                          {
                            'id_historico': entry['id_historico'] ?? entry['id'],
                            'id_utilizador': entry['id_utilizador'] ?? entry['user_id'],
                            'id_submissao': remoteId,
                            'aceite': (entry['aceite'] == true || entry['aceite'] == 1) ? 1 : 0,
                            'data_avaliacao': entry['data_avaliacao']?.toString() ??
                                DateTime.now().toUtc().toIso8601String(),
                            'feedback': entry['feedback']?.toString(),
                            'historico_json': jsonEncode(entry),
                          },
                          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
                        );
                      } catch (_) {}
                    }
                    // Extrair feedback da entrada mais recente rejeitada
                    for (final entry in hist) {
                      final aceite = entry['aceite'];
                      final isRejected = aceite == 0 || aceite == false || aceite == '0';
                      final fb = entry['feedback']?.toString();
                      if (isRejected && fb != null && fb.isNotEmpty) {
                        feedback = fb;
                        break;
                      }
                    }
                  }
                }
              } catch (e) {
                debugPrint('⚠️ [BadgeDetalhe] Erro ao buscar historico da API: $e');
              }
            }

            debugPrint('🔍 [BadgeDetalhe] feedback resolvido: "$feedback"');
          }
        }

        // Calcular data de expiração
        if (estado.contains('expir')) {
          final rows = await db.rawQuery('''
            SELECT rb.data_obtencao, b.validade
            FROM ${DatabaseSchema.registoBadgesTable} rb
            INNER JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = rb.id_badge
            WHERE rb.id_utilizador = ? AND rb.id_badge = ?
              AND (rb.deleted_registo IS NOT 1)
            ORDER BY rb.data_obtencao DESC
            LIMIT 1
          ''', [userId, badgeId]);
          if (rows.isNotEmpty) {
            final dataObtencao = rows.first['data_obtencao'] as String?;
            final validade = rows.first['validade'];
            final validadeDias = validade is int ? validade : int.tryParse(validade?.toString() ?? '');
            if (dataObtencao != null && validadeDias != null && validadeDias > 0) {
              final dt = DateTime.tryParse(dataObtencao);
              if (dt != null) {
                final expiry = dt.add(Duration(days: validadeDias));
                dataExpiracao =
                    '${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}';
              }
            }
          }
        }

        int? submissaoLocalId;
        Map<int, Map<String, dynamic>> reqDocs = {};

        // Procurar submissão em progresso ou recusada para ler/adicionar evidências
        final subRows = await db.query(
          DatabaseSchema.submissoesTable,
          columns: ['id_submissao_local', 'status'],
          where: 'id_utilizador = ? AND id_badge = ? AND deleted_submissao IS NULL',
          whereArgs: [userId, badgeId],
          orderBy: 'id_submissao_local DESC',
          limit: 1,
        );

        if (subRows.isNotEmpty) {
          final status = subRows.first['status']?.toString().toLowerCase() ?? '';
          if (status == 'em_progresso' || status == 'rascunho' || status == 'draft' || status == 'emprogresso' || status == 'recusado' || status == 'recusada' || status == 'rejeitado' || status == 'rejeitada') {
            submissaoLocalId = subRows.first['id_submissao_local'] as int?;
          }
        }

        if (submissaoLocalId == null) {
          final estado = _estadoNormalizado;
          if (estado == 'em_progresso' || estado == 'emprogresso' || estado == 'draft' || estado == 'rascunho') {
            debugPrint('⚙️ [BadgeDetalhe] Estado do widget é "em progresso" mas não existe linha local. A criar rascunho automaticamente...');
            submissaoLocalId = await SubmissoesDao.instance.obterOuCriarRascunhoLocal(
              userId: userId,
              idBadge: badgeId,
            );
          }
        }

        if (submissaoLocalId != null) {
          final docsList = await SubmissoesDao.instance.listarDocumentosDaSubmissao(
            userId: userId,
            submissaoLocalId: submissaoLocalId,
          );
          for (final doc in docsList) {
            final reqId = int.tryParse(doc['id_requisito']?.toString() ?? doc['requisito_id']?.toString() ?? '');
            if (reqId != null && (doc['deleted_file'] == 0 || doc['deleted_file'] == false || doc['deleted_file'] == null || doc['deleted_file'] == '0' || doc['deleted_file'] == 'false')) {
              reqDocs[reqId] = doc;
            }
          }
        }

        final reqs = await RequisitosDao.instance.obterRequisitosComEstado(
          badgeId: badgeId,
          userId: userId,
        );

        if (mounted) {
          setState(() {
            _requisitos = reqs;
            _feedbackRejeicao = feedback;
            _dataExpiracao = dataExpiracao;
            _submissaoLocalId = submissaoLocalId;
            _requisitoDocumentos = reqDocs;
            _loadingRequisitos = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingRequisitos = false;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [BadgeDetalheScreen] Erro ao carregar requisitos: $e');
      if (mounted) {
        setState(() {
          _loadingRequisitos = false;
        });
      }
    }
  }

  bool get _isEditavel {
    final estado = _estadoNormalizado;
    return !(estado.contains('conquist') ||
        estado.contains('aprovado') ||
        estado.contains('pendente') ||
        estado.contains('pending'));
  }

  Future<void> _iniciarCandidatura() async {
    try {
      final userId = int.tryParse(AuthController.instance.currentUser?['id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['user_id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['id_utilizador']?.toString() ?? '') ??
          1;

      var badgeId = int.tryParse(widget.badge['id_badge']?.toString() ?? '') ??
          int.tryParse(widget.badge['id']?.toString() ?? '');

      if (badgeId == null) return;

      setState(() {
        _loadingRequisitos = true;
      });

      await SubmissoesDao.instance.obterOuCriarRascunhoLocal(
        userId: userId,
        idBadge: badgeId,
      );

      // Atualizar status local no widget.badge
      widget.badge['status'] = 'em_progresso';
      widget.badge['estado'] = 'em_progresso';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidatura iniciada com sucesso!')),
        );
      }

      await _carregarRequisitos();
      SyncManager.instance.syncAll(userId).catchError((e) => debugPrint('Sync error: $e'));
    } catch (e) {
      debugPrint('⚠️ Erro ao iniciar candidatura: $e');
      if (mounted) {
        setState(() {
          _loadingRequisitos = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar candidatura: $e')),
        );
      }
    }
  }

  Future<void> _adicionarEvidencia(int requisitoId) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx'],
      );

      if (result == null || result.files.single.path == null) {
        debugPrint('⚠️ [Evidência] Seleção de ficheiro cancelada pelo utilizador.');
        return;
      }

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      debugPrint('📁 [Evidência] Ficheiro selecionado: $fileName ($filePath)');

      final userId = int.tryParse(AuthController.instance.currentUser?['id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['user_id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['id_utilizador']?.toString() ?? '') ??
          1;

      var badgeId = int.tryParse(widget.badge['id_badge']?.toString() ?? '') ??
          int.tryParse(widget.badge['id']?.toString() ?? '');

      if (badgeId == null) {
        debugPrint('⚠️ [Evidência] badgeId nulo — a abortar.');
        return;
      }

      setState(() {
        _loadingRequisitos = true;
      });

      final db = await DatabaseHelper.instance.database;

      // Obter ou criar submissão ativa
      var subId = _submissaoLocalId;
      if (subId == null) {
        subId = await SubmissoesDao.instance.obterOuCriarRascunhoLocal(
          userId: userId,
          idBadge: badgeId,
        );
      }
      debugPrint('✅ [Evidência] Submissão resolvida: id_submissao_local=$subId');

      // a) Garante que o rascunho local tem ID remoto. Se 'id_submissao' for NULL, executa um Push rápido síncrono
      var subRows = await db.query(
        DatabaseSchema.submissoesTable,
        columns: ['id_submissao'],
        where: 'id_submissao_local = ?',
        whereArgs: [subId],
        limit: 1,
      );

      if (subRows.isEmpty || subRows.first['id_submissao'] == null) {
        debugPrint('🔄 [Evidência] Rascunho local $subId não tem ID remoto. A forçar Push síncrono...');
        await SyncManager.instance.executePushSync(userId);
        
        // Re-consultar
        subRows = await db.query(
          DatabaseSchema.submissoesTable,
          columns: ['id_submissao'],
          where: 'id_submissao_local = ?',
          whereArgs: [subId],
          limit: 1,
        );
      }

      final int? remoteSubId = subRows.isNotEmpty ? intOrNull(subRows.first['id_submissao']) : null;
      if (remoteSubId == null) {
        throw Exception('Não foi possível obter o ID remoto da submissão no servidor. Verifique a rede e tente novamente.');
      }

      // b) Com o 'id_submissao' (81) resolvido, chama IMEDIATAMENTE o upload do ficheiro via Multipart ('/api/mobile/upload') sem adiar.
      debugPrint('📤 [Evidência] A enviar ficheiro física e imediatamente para o servidor: $filePath');
      final uploadRes = await SyncManager.instance.uploadEvidence(filePath, {
        'id_submissao': remoteSubId,
        'id_requisito': requisitoId,
      });

      if (uploadRes == null || uploadRes['success'] != true) {
        throw Exception('Falha no upload físico do ficheiro no servidor.');
      }

      final int? remoteFileId = intOrNull(uploadRes['id'] ?? uploadRes['id_ficheiro'] ?? uploadRes['data']?['id_ficheiro']);
      final String? serverUrl = (uploadRes['url'] ?? uploadRes['url_ficheiro'] ?? uploadRes['data']?['url'])?.toString();

      if (serverUrl == null) {
        throw Exception('Servidor não retornou o URL do ficheiro após o upload.');
      }

      // c) Guarda o URL retornado pelo servidor na BD local e atualiza a UI instantaneamente.
      final docLocalId = await db.transaction((txn) async {
        final id = await txn.insert(DatabaseSchema.documentosSubmissaoTable, {
          'id_submissao_local': subId,
          'id_submissao': remoteSubId,
          'id_requisito': requisitoId,
          'ficheiro': fileName,
          'ficheiro_local': filePath,
          'url_ficheiro': serverUrl,
          'id_ficheiro': remoteFileId,
          'tamanho_bytes': result.files.single.size,
          'created_local_at': utcNow(),
          'sync_status': 'synced',
        });
        return id;
      });
      debugPrint('📄 [Evidência] Documento gravado no SQLite local com URL remoto resolvido (docLocalId=$docLocalId, url=$serverUrl, id_ficheiro=$remoteFileId)');

      // 4. Atualizar status da submissão para em_progresso localmente
      await db.update(
        DatabaseSchema.submissoesTable,
        {'status': 'em_progresso'},
        where: 'id_submissao_local = ?',
        whereArgs: [subId],
      );

      widget.badge['status'] = 'em_progresso';
      widget.badge['estado'] = 'em_progresso';

      // 5. Actualizar UI reactivamente e mostrar confirmação
      await _carregarRequisitos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Evidência "$fileName" enviada com sucesso!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e, stack) {
      debugPrint('💥 EXCEÇÃO REAL CAPTURADA: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          _loadingRequisitos = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar evidência: $e')),
        );
      }
    }
  }

  Future<void> _removerEvidencia(Map<String, dynamic> doc) async {
    try {
      final docLocalId = int.tryParse(doc['id_documento_local']?.toString() ?? '') ??
          int.tryParse(doc['id_ficheiro_local']?.toString() ?? '');
      if (docLocalId == null) return;

      final userId = int.tryParse(AuthController.instance.currentUser?['id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['user_id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['id_utilizador']?.toString() ?? '') ??
          1;

      setState(() {
        _loadingRequisitos = true;
      });

      await SubmissoesDao.instance.marcarDocumentoParaEliminacao(
        userId: userId,
        localId: docLocalId,
      );

      await _carregarRequisitos();
      SyncManager.instance.syncAll(userId).catchError((e) => debugPrint('Sync error: $e'));
    } catch (e) {
      debugPrint('⚠️ Erro ao remover evidência: $e');
      if (mounted) {
        setState(() {
          _loadingRequisitos = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover evidência: $e')),
        );
      }
    }
  }

  Future<void> _submeterCandidatura() async {
    try {
      final userId = int.tryParse(AuthController.instance.currentUser?['id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['user_id']?.toString() ?? '') ??
          int.tryParse(AuthController.instance.currentUser?['id_utilizador']?.toString() ?? '') ??
          1;

      var badgeId = int.tryParse(widget.badge['id_badge']?.toString() ?? '') ??
          int.tryParse(widget.badge['id']?.toString() ?? '');

      if (badgeId == null) {
        debugPrint('⚠️ [Submeter] badgeId nulo — a abortar.');
        return;
      }

      setState(() {
        _loadingRequisitos = true;
      });

      var subId = _submissaoLocalId;
      if (subId == null) {
        final db = await DatabaseHelper.instance.database;
        final subRows = await db.query(
          DatabaseSchema.submissoesTable,
          columns: ['id_submissao_local', 'status'],
          where: 'id_utilizador = ? AND id_badge = ? AND deleted_submissao IS NULL',
          whereArgs: [userId, badgeId],
          orderBy: 'id_submissao_local DESC',
          limit: 1,
        );
        if (subRows.isNotEmpty) {
          final status = subRows.first['status']?.toString().toLowerCase() ?? '';
          if (!['aprovado', 'aprovada', 'conquistado', 'conquistada', 'expirado', 'expirada'].contains(status)) {
            subId = subRows.first['id_submissao_local'] as int?;
          }
        }
      }

      if (subId == null) {
        subId = await SubmissoesDao.instance.obterOuCriarRascunhoLocal(
          userId: userId,
          idBadge: badgeId,
        );
      }

      // 3. Marcar a candidatura como submetida/pendente via DAO (atualiza SQLite + outbox)
      debugPrint('📤 [Submeter] A submeter candidatura id_submissao_local=$subId (user=$userId)...');
      await SubmissoesDao.instance.pedirSubmissaoLocal(
        userId: userId,
        localId: subId,
      );
      debugPrint('✅ [Submeter] Candidatura marcada como pendente no SQLite.');

      widget.badge['status'] = 'pendente';
      widget.badge['estado'] = 'pendente';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Candidatura submetida com sucesso! Em avaliação...'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // 4. Atualizar a UI
      await _carregarRequisitos();

      // 5. Disparar push sync em background sem bloquear a UI
      SyncManager.instance.executePushSync(userId).catchError((e) {
        debugPrint('⚠️ Sync error: $e');
        return false;
      });

    } catch (e) {
      debugPrint('⚠️ Erro ao submeter candidatura: $e');
      if (mounted) {
        setState(() {
          _loadingRequisitos = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao submeter candidatura: $e')),
        );
      }
    }
  }

  bool get _isConquistado {
    final estado = _estadoNormalizado;
    return estado.contains('conquist') || estado.contains('aprovado');
  }

  Future<void> _partilharLinkedin() async {
    final String text = 'Conquistei o Badge "$_titulo" na Softinsa!';
    final String url = 'https://softinsa.pt'; // Softinsa portal link
    final Uri linkedinUri = Uri.parse(
      'https://www.linkedin.com/shareArticle?mini=true&url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent(text)}&summary=${Uri.encodeComponent(text)}'
    );
    try {
      await launchUrl(linkedinUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Erro ao partilhar no LinkedIn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao partilhar no LinkedIn: $e')),
        );
      }
    }
  }

  Widget _buildEvidenciaSeccao(Map<String, dynamic> req) {
    final reqId = int.tryParse(req['id_requisito']?.toString() ?? '');
    if (reqId == null) return const SizedBox.shrink();

    final doc = _requisitoDocumentos[reqId];
    if (doc != null) {
      final String nomeFicheiro = doc['nome_ficheiro']?.toString() ?? 
                                  doc['caminho_local']?.toString().split('/').last ?? 
                                  'Evidência';
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppCores.branco,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppCores.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 18, color: AppCores.azulFundo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nomeFicheiro,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              onPressed: () => _removerEvidencia(doc),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            side: const BorderSide(color: AppCores.azulFundo, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppCores.azulFundo),
          label: const Text(
            'Adicionar Evidência',
            style: TextStyle(
              color: AppCores.azulFundo,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () => _adicionarEvidencia(reqId),
        ),
      );
    }
  }

  // ── Helpers de leitura ────────────────────────────────────────────────────

  String get _titulo {
    for (final k in ['titulo', 'title', 'nome_badge']) {
      final v = widget.badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return 'Badge';
  }

  String get _descricao {
    for (final k in ['descricao', 'descricao_badge']) {
      final v = widget.badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String get _area {
    for (final k in ['areaNome', 'area', 'categoria', 'category', 'subtitulo']) {
      final v = widget.badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String get _nivel {
    for (final k in ['nivelNome', 'nivel']) {
      final v = widget.badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  int get _pontos {
    for (final k in ['pontos', 'points']) {
      final v = widget.badge[k];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  int get _validadeDias {
    final v = widget.badge['validadeDias'];
    return v is num ? v.toInt() : 0;
  }

  bool get _especial {
    final v = widget.badge['especial'];
    return v == true || v == '1' || v == 1;
  }

  String? get _imagem {
    final v = widget.badge['imagem'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  IconData? get _icon => widget.badge['icon'] as IconData?;

  Color get _avatarColor {
    final v = widget.badge['avatarColor'];
    return v is Color ? v : AppCores.azulFundo;
  }

  String get _estadoNormalizado {
    for (final k in ['estado', 'status']) {
      final v = widget.badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim().toLowerCase();
    }
    return '';
  }

  bool get _requisitosCompletos {
    if (_requisitos.isEmpty) return false;
    return _requisitos.every((req) {
      final reqId = int.tryParse(req['id_requisito']?.toString() ?? req['id']?.toString() ?? '');
      return reqId != null && _requisitoDocumentos.containsKey(reqId);
    });
  }

  int get _progressoCalculado {
    if (_requisitos.isEmpty) return 0;
    final anexados = _requisitos.where((req) {
      final reqId = int.tryParse(req['id_requisito']?.toString() ?? req['id']?.toString() ?? '');
      return reqId != null && _requisitoDocumentos.containsKey(reqId);
    }).length;
    return ((anexados / _requisitos.length) * 100).round();
  }


  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar({double size = 108}) {
    final imagem = _imagem;
    final hasNetworkImage = imagem != null &&
        (imagem.startsWith('http://') || imagem.startsWith('https://'));
    final icon = _icon;

    Widget inner;
    if (hasNetworkImage) {
      inner = Image.network(
        imagem,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context2, error, stackTrace) => _placeholderAvatar(size),
      );
    } else if (icon != null) {
      inner = Container(
        width: size,
        height: size,
        color: _avatarColor.withValues(alpha: 0.15),
        child: Center(
          child: Icon(icon, color: _avatarColor, size: size * 0.42),
        ),
      );
    } else {
      inner = _placeholderAvatar(size);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: _especial
                ? Border.all(color: const Color(0xFFF8AA0B), width: 3)
                : Border.all(color: AppCores.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: inner,
        ),
        if (_especial)
          Positioned(
            top: -2,
            left: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF3E), Color(0xFFF8AA0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _placeholderAvatar(double size) {
    const List<Color> paleta = [
      Color(0xFF4F8EF7), Color(0xFF62C884), Color(0xFFF8AA0B),
      Color(0xFFE96A6A), Color(0xFF9B6AF7), Color(0xFF00BFAE),
      Color(0xFFFF7043), Color(0xFF26A69A),
    ];
    final cor = paleta[
      _titulo.isEmpty ? 0 : _titulo.codeUnits.fold(0, (a, b) => a + b) % paleta.length
    ];
    return Container(
      width: size,
      height: size,
      color: cor,
      alignment: Alignment.center,
      child: Text(
        _titulo.isNotEmpty ? _titulo[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.37,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Meta chip ─────────────────────────────────────────────────────────────

  Widget _meta(IconData icon, String texto) {
    if (texto.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.loginCampo),
        border: Border.all(color: AppCores.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppCores.azulFundo),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Secção Hero ───────────────────────────────────────────────────────────

  Widget _buildHero(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppCores.fundo2,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          Text(
            _titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _descricao,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppCores.fontes.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_pontos > 0)
                _meta(Icons.school_outlined, '$_pontos ${l10n.pts}'),
              if (_nivel.isNotEmpty)
                _meta(Icons.signal_cellular_alt_rounded, _nivel),
              if (_area.isNotEmpty)
                _meta(Icons.work_outline_rounded, _area),
              _meta(
                _especial ? Icons.star_rounded : Icons.badge_outlined,
                _especial ? l10n.especial : l10n.normal,
              ),
              if (_validadeDias > 0)
                _meta(Icons.event_outlined, '$_validadeDias ${l10n.dias}'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Secção Estado ─────────────────────────────────────────────────────────

  Widget? _buildEstadoCard(AppLocalizations l10n) {
    final estado = _estadoNormalizado;
    if (estado.isEmpty) return null;

    Color cor;
    Color fundo;
    IconData icone;
    String titulo;
    String descricao;
    // Extra info (feedback ou data expiração)
    String? extra;

    if (estado.contains('conquist') || estado.contains('aprovado')) {
      cor = const Color(0xFF009966);
      fundo = const Color(0xFFEDF9F3);
      icone = Icons.check_rounded;
      titulo = l10n.badgeConquistado;
      descricao = l10n.badgeConquistadoDesc;
    } else if (estado.contains('pendente') || estado.contains('pending')) {
      cor = const Color(0xFFF59E0B);
      fundo = const Color(0xFFFFF8E7);
      icone = Icons.schedule_rounded;
      titulo = l10n.candidaturaAnalise;
      descricao = l10n.candidaturaAnaliseDesc;
    } else if (estado.contains('progresso') || estado.contains('progress')) {
      cor = AppCores.azulFundo;
      fundo = const Color(0xFFF0F5FB);
      icone = Icons.edit_document;
      titulo = l10n.candidaturaProgresso;
      descricao = '$_progressoCalculado% ${l10n.completo}';
    } else if (estado.contains('recusado') || estado.contains('rejeit')) {
      cor = const Color(0xFFD42A2A);
      fundo = const Color(0xFFFFF1F1);
      icone = Icons.close_rounded;
      titulo = l10n.candidaturaRecusada;
      descricao = l10n.candidaturaRecusadaDesc;
      if (_feedbackRejeicao != null && _feedbackRejeicao!.trim().isNotEmpty) {
        extra = _feedbackRejeicao!.trim();
      }
    } else if (estado.contains('expir')) {
      cor = const Color(0xFFC62828);
      fundo = const Color(0xFFFFF1F1);
      icone = Icons.history_toggle_off_rounded;
      titulo = l10n.badgeExpirado;
      descricao = l10n.badgeExpiradoDesc;
      if (_dataExpiracao != null) {
        extra = 'Expirou a $_dataExpiracao';
      }
    } else if (estado.contains('bloqueado') || estado.contains('disponi')) {
      cor = const Color(0xFF6B7280);
      fundo = const Color(0xFFF3F4F6);
      icone = Icons.lock_outline_rounded;
      titulo = l10n.badgeDisponivel;
      descricao = l10n.badgeDisponivelDesc;
    } else {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                child: Icon(icone, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: cor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(
                        color: AppCores.fontes,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (estado.contains('progresso') || estado.contains('progress')) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_progressoCalculado.clamp(0, 100)) / 100,
                minHeight: 8,
                backgroundColor: AppCores.outline,
                color: cor,
              ),
            ),
          ],
          // Bloco extra: feedback de rejeição ou data de expiração
          if (extra != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    estado.contains('expir')
                        ? Icons.calendar_today_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: cor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      extra,
                      style: TextStyle(
                        color: cor.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                        fontStyle: estado.contains('expir')
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Lista Dinâmica de Requisitos ──────────────────────────────────────────

  Widget _buildRequisitosList(AppLocalizations l10n) {
    if (_loadingRequisitos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(
            color: AppCores.azulFundo,
          ),
        ),
      );
    }

    if (_requisitos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppCores.fundo2,
          borderRadius: BorderRadius.circular(AppBorders.padrao),
          border: Border.all(color: AppCores.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppCores.fontes.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sem requisitos registados para este badge.',
                style: TextStyle(
                  color: AppCores.fontes.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _requisitos.length,
      separatorBuilder: (context2, index2) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = _requisitos[index];
        final bool cumprido = req['cumprido'] as bool? ?? false;
        final String nome = req['nome_requisito'] as String? ?? '';
        final String desc = req['descricao_requisito'] as String? ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cumprido ? const Color(0xFFEDF9F3) : AppCores.branco,
            borderRadius: BorderRadius.circular(AppBorders.padrao),
            border: Border.all(
              color: cumprido ? const Color(0xFF009966).withValues(alpha: 0.3) : AppCores.outline,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cumprido ? const Color(0xFF009966) : AppCores.fundo2,
                  shape: BoxShape.circle,
                  border: cumprido ? null : Border.all(color: AppCores.outline, width: 1.5),
                ),
                child: Icon(
                  cumprido ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                  color: cumprido ? Colors.white : AppCores.fontes.withValues(alpha: 0.4),
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: TextStyle(
                        color: cumprido ? const Color(0xFF006644) : AppCores.fontes,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          color: AppCores.fontes.withValues(alpha: 0.65),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (!cumprido && _isEditavel && _submissaoLocalId != null) ...[
                      _buildEvidenciaSeccao(req),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final estadoCard = _buildEstadoCard(l10n);

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.voltar,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppCores.fontes,
            size: AppTamanhos.iconeNavegacao,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.detalheBadge,
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: AppTamanhos.titulo,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTamanhos.margemEcra,
          8,
          AppTamanhos.margemEcra,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(l10n),
            if (estadoCard != null) ...[
              const SizedBox(height: 16),
              estadoCard,
            ],
            const SizedBox(height: 24),
            Text(
              l10n.requisitosEvidencias,
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRequisitosList(l10n),
            if (_isEditavel) ...[
              const SizedBox(height: 24),
              if (_submissaoLocalId == null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppCores.azulFundo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'INICIAR CANDIDATURA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _iniciarCandidatura,
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _requisitosCompletos ? AppCores.azulFundo : Colors.grey.shade400,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.send_rounded, color: _requisitosCompletos ? Colors.white : Colors.white70, size: 20),
                  label: Text(
                    _requisitosCompletos ? 'SUBMETER CANDIDATURA' : 'ANEXE TODOS OS REQUISITOS',
                    style: TextStyle(
                      color: _requisitosCompletos ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _requisitosCompletos ? _submeterCandidatura : null,
                ),
            ],
            if (_isConquistado) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B5), // LinkedIn blue color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                label: const Text(
                  'PARTILHAR NO LINKEDIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _partilharLinkedin,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
