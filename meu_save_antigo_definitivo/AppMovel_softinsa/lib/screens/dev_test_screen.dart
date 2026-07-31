import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/database_schema.dart';
import '../database/sync_manager.dart';
import '../database/daos/submissao_dao.dart';
import '../database/daos/objetivo_dao.dart';
import '../database/daos/perfil_dao.dart';
import '../database/daos/assinaturas_dao.dart';
import '../database/daos/sync_outbox_dao.dart';

class DevTestScreen extends StatefulWidget {
  final int userId;

  const DevTestScreen({super.key, required this.userId});

  @override
  State<DevTestScreen> createState() => _DevTestScreenState();
}

class _DevTestScreenState extends State<DevTestScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  void _addLog(String message, {bool isError = false}) {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    setState(() {
      _logs.add("[$timeStr] ${isError ? '🔴 ' : '🟢 '}$message");
    });
    // Auto-scroll log console to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _simularCriacaoOffline() async {
    setState(() => _isProcessing = true);
    _addLog("A simular criação offline de submissão...");
    try {
      final db = await DatabaseHelper.instance.database;

      // Procurar um badgeId existente no SQLite para evitar violação de FK
      final badges = await db.query(DatabaseSchema.badgesTable,
          columns: ['id_badge'], limit: 1);
      int badgeId = 1;
      if (badges.isNotEmpty) {
        badgeId = badges.first['id_badge'] as int;
      }

      _addLog("A criar rascunho local no SQLite com id_badge: $badgeId...");
      final localId = await SubmissoesDao.instance.criarRascunhoLocal(
        userId: widget.userId,
        badgeId: badgeId,
      );

      _addLog("Sucesso! Criado id_submissao_local: $localId");
      _addLog("Fila do outbox atualizada com status = pending.");
    } catch (e) {
      _addLog("Erro na criação offline: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _simularCriarObjetivoOffline() async {
    setState(() => _isProcessing = true);
    _addLog("A simular criação offline de objetivo...");
    try {
      final db = await DatabaseHelper.instance.database;

      // Procurar um badgeId existente no SQLite para evitar violação de FK
      final badges = await db.query(DatabaseSchema.badgesTable,
          columns: ['id_badge'], limit: 1);
      int badgeId = 1;
      if (badges.isNotEmpty) {
        badgeId = badges.first['id_badge'] as int;
      } else {
        _addLog("A criar badge dummy com ID = 1 no SQLite para evitar restrição de chave estrangeira...");
        await db.insert(DatabaseSchema.badgesTable, {
          'id_badge': 1,
          'nome_badge': 'Badge Geral',
          'descricao_badge': 'Badge inicial de testes',
          'especial': 0,
        });
      }

      final dateStr = "2027-12-31";
      _addLog("A criar objetivo local no SQLite com id_badge: $badgeId...");
      
      final localId = await ObjetivosDao.instance.criarObjetivoLocal(
        userId: widget.userId,
        badgeId: badgeId,
        dataFinal: dateStr,
        titulo: "Objetivo de Teste Offline",
        descricao: "Criado via DevTestScreen",
      );

      _addLog("🎯 Objetivo offline criado com sucesso (ID Local: $localId)!");
    } catch (e, stack) {
      print('💥 [ERRO SQLITE LOCAL]: Falha ao inserir registo: $e');
      print('💥 Stack trace: $stack');
      _addLog("Erro na criação offline de objetivo: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _simularCriarDocumentoOffline() async {
    setState(() => _isProcessing = true);
    _addLog("A simular criação offline de documento...");
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Procurar uma submissão existente ou criar uma nova se não existir nenhuma
      final subs = await db.query(DatabaseSchema.submissoesTable,
          columns: ['id_submissao_local'], orderBy: 'id_submissao_local DESC', limit: 1);
      int subLocalId;
      if (subs.isNotEmpty) {
        subLocalId = subs.first['id_submissao_local'] as int;
      } else {
        // Procurar badge existente
        final badges = await db.query(DatabaseSchema.badgesTable,
            columns: ['id_badge'], limit: 1);
        int badgeId = 1;
        if (badges.isNotEmpty) {
          badgeId = badges.first['id_badge'] as int;
        } else {
          await db.insert(DatabaseSchema.badgesTable, {
            'id_badge': 1,
            'nome_badge': 'Badge Geral',
            'descricao_badge': 'Badge inicial de testes',
            'especial': 0,
          });
        }
        
        _addLog("Nenhuma submissão existente encontrada. A criar submissão automática...");
        subLocalId = await SubmissoesDao.instance.criarRascunhoLocal(
          userId: widget.userId,
          badgeId: badgeId,
        );
        _addLog("✅ Submissão automática criada (ID Local: $subLocalId).");
      }

      // 2. Garantir que o requisito com ID = 1 existe na base de dados local para não quebrar a FK
      final reqs = await db.query(DatabaseSchema.requisitosTable,
          columns: ['id_requisito'], where: 'id_requisito = ?', whereArgs: [1], limit: 1);
      if (reqs.isEmpty) {
        _addLog("A criar requisito dummy com ID = 1 no SQLite para evitar restrição de chave estrangeira...");
        await db.insert(DatabaseSchema.requisitosTable, {
          'id_requisito': 1,
          'nome_requisito': 'Requisito de Teste',
          'descricao_requisito': 'Descrição de teste',
          'deleted_requisito': '0',
        });
      }

      // 3. Inserir o documento e associar a outbox
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final clientId = "client_doc_${DateTime.now().millisecondsSinceEpoch}";

      final localId = await db.transaction((txn) async {
        final id = await txn.insert(DatabaseSchema.documentosSubmissaoTable, {
          'id_submissao_local': subLocalId,
          'id_requisito': 1,
          'ficheiro': "comprovativo_teste.pdf",
          'ficheiro_local': "https://exemplo.com/teste.pdf",
          'tamanho_bytes': 1024,
          'upload_status': 'pendente',
          'created_local_at': nowStr,
          'sync_status': 'pending_insert',
        });

        await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
          txn,
          userId: widget.userId,
          entity: 'documentos_submissao',
          operation: 'insert',
          localRecordId: id,
          clientId: clientId,
          payload: {
            'client_id': clientId,
            'id_submissao_local': subLocalId,
            'id_requisito': 1,
            'nome_ficheiro': "comprovativo_teste.pdf",
            'url_ficheiro': "https://exemplo.com/teste.pdf",
          },
        );
        return id;
      });

      _addLog("📄 Documento offline criado com sucesso (ID Local: $localId)!");
    } catch (e, stack) {
      print('💥 [ERRO SQLITE LOCAL]: Falha ao inserir registo: $e');
      print('💥 Stack trace: $stack');
      _addLog("Erro na criação offline de documento: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _simularEdicaoPerfilOffline() async {
    setState(() => _isProcessing = true);
    _addLog("A simular edição offline do perfil...");
    try {
      final now = DateTime.now();
      final novoNome = 'José Silva (Editado às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')})';
      
      final Map<String, dynamic> payloadPerfil = {
        'nome': novoNome,
        'telefone': '912345678',
        'email': 'jose.silva@exemplo.com',
        'updated_at': now.toIso8601String(),
      };

      await PerfilDao.instance.guardarPerfilLocal(
        userId: widget.userId,
        perfil: payloadPerfil,
      );

      _addLog("👤 Perfil editado offline com sucesso!");
      print('🧪 [TESTE PERFIL] Perfil atualizado no SQLite local e registado na sync_outbox.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil editado localmente e adicionado à Outbox!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      print('💥 [ERRO SQLITE LOCAL PERFIL]: Falha ao atualizar perfil: $e');
      print('💥 Stack trace: $stack');
      _addLog("Erro ao editar perfil: $e", isError: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao editar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _simularAssinaturaOffline() async {
    setState(() => _isProcessing = true);
    _addLog("A simular criação/atualização offline da assinatura...");
    try {
      final timestamp = DateTime.now().toIso8601String();
      final Map<String, dynamic> payloadAssinatura = {
        'client_id': 'client_sig_${DateTime.now().millisecondsSinceEpoch}',
        'dados_assinatura': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        'formato': 'png',
        'data_assinatura': timestamp,
        'updated_at': timestamp,
      };

      await AssinaturasDao.instance.guardarAssinaturaLocal(
        userId: widget.userId,
        assinatura: payloadAssinatura,
      );

      _addLog("✍️ Assinatura guardada/atualizada offline com sucesso!");
      print('🧪 [TESTE ASSINATURA] Assinatura atualizada no SQLite local e registada na sync_outbox.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Assinatura simulada e registada na Outbox!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      print('💥 [ERRO SQLITE LOCAL ASSINATURA]: Falha ao guardar assinatura: $e');
      print('💥 Stack trace: $stack');
      _addLog("Erro ao guardar assinatura: $e", isError: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao simular assinatura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _executarPushSync() async {
    setState(() => _isProcessing = true);
    _addLog("A iniciar executePushSync()...");
    try {
      final syncManager = SyncManager();
      final success = await syncManager.executePushSync(widget.userId);
      if (success) {
        _addLog("Push Sync concluído. IDs locais atualizados e outbox limpo.");
      } else {
        _addLog("Push Sync falhou ou não enviou dados. Verifique os logs do terminal.",
            isError: true);
      }
    } catch (e) {
      _addLog("Erro no Push Sync: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _executarPullSync() async {
    setState(() => _isProcessing = true);
    _addLog("A iniciar executePullSync()...");
    try {
      final syncManager = SyncManager();
      final success = await syncManager.executePullSync(widget.userId);
      if (success) {
        _addLog("Pull Sync concluído. Dados do servidor atualizados localmente.");
      } else {
        _addLog("Pull Sync falhou. Verifique os logs do terminal.", isError: true);
      }
    } catch (e) {
      _addLog("Erro no Pull Sync: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _executarCicloCompleto() async {
    setState(() => _isProcessing = true);
    _addLog("A iniciar syncAll() (Ciclo Completo)...");
    try {
      final syncManager = SyncManager();
      await syncManager.syncAll(widget.userId);
      _addLog("Ciclo de sincronização completo concluído: Push -> Pull.");
    } catch (e) {
      _addLog("Erro no Ciclo Completo: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _limparLogs() async {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevTestScreen — Painel de Testes do Sync'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SECÇÃO: SIMULAÇÕES OFFLINE ---
                    const Text(
                      '📴 SIMULAÇÕES OFFLINE (Drafts)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _simularCriacaoOffline,
                      icon: const Icon(Icons.description),
                      label: const Text('CRIAR SUBMISSÃO OFFLINE'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.amber[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _simularCriarObjetivoOffline,
                      icon: const Icon(Icons.track_changes),
                      label: const Text('CRIAR OBJETIVO OFFLINE'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _simularCriarDocumentoOffline,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('CRIAR DOCUMENTO OFFLINE'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepOrange[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _simularEdicaoPerfilOffline,
                      icon: const Icon(Icons.person),
                      label: const Text('EDITAR PERFIL OFFLINE'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _simularAssinaturaOffline,
                      icon: const Icon(Icons.gesture),
                      label: const Text('SIMULAR ASSINATURA OFFLINE'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.brown[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- SECÇÃO: AÇÕES DE SYNC ---
                    const Text(
                      '🔄 SINCRONIZAÇÃO BIDIRECIONAL',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _executarPushSync,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('EXECUTAR PUSH SYNC (Mobile -> Web)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _executarPullSync,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('EXECUTAR PULL SYNC (Web -> Mobile)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.teal[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _executarCicloCompleto,
                      icon: const Icon(Icons.sync),
                      label: const Text('EXECUTAR CICLO COMPLETO (Push -> Pull)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.purple[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _limparLogs,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('LIMPAR CONSOLA DE LOGS'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Consola Visual de Logs
          Container(
            height: 280, // Altura fixa para evitar RenderFlex overflow
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💻 CONSOLA DE LOGS DO PROGRAMADOR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Divider(color: Colors.white24, thickness: 1),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
