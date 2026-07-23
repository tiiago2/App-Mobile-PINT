/*import 'package:flutter/foundation.dart';
import '../database/basededados.dart';
import 'api_service.dart';

class SyncService {
  final ApiService _apiService = ApiService();
  final Basededados _db = Basededados();

  /// Executa o processo de sincronização completo (Delta Sync)
  Future<void> syncData() async {
    try {
      if (kDebugMode) {
        print("A iniciar Sincronização Incremental (Delta Sync)...");
      }

      // 1. Ler o Timestamp local
      final String lastSyncTime = await _db.getLastSyncTimestamp();
      if (kDebugMode) {
        print("Última sincronização registada: \${lastSyncTime.isEmpty ? 'Nenhuma' : lastSyncTime}");
      }

      // 2. Chamar a API a pedir apenas os dados que mudaram desde esse Timestamp
      final Map<String, dynamic> updates = await _apiService.fetchUpdatesSince(lastSyncTime);

      // Se a resposta contiver atualizações
      if (updates.containsKey('server_timestamp')) {
        final String newServerTime = updates['server_timestamp'];

        // 3. Atualizar a Tabela Perfil (Upsert + Soft Delete manual logicamente feito pelo insert)
        // Se a BD tivesse registos enormes faríamos delete explícito, 
        // mas aqui basta inserir e o "ativo" tratará de o esconder se for 0.
        if (updates['perfil_updates'] != null) {
          final List<dynamic> perfis = updates['perfil_updates'];
          for (var p in perfis) {
            await _db.upsertPerfil(p);
            if (kDebugMode) print("Sincronizado perfil: \${p['nome']}");
          }
        }

        // 4. Atualizar a Tabela Badges
        if (updates['badges_updates'] != null) {
          final List<dynamic> badges = updates['badges_updates'];
          for (var b in badges) {
            await _db.upsertBadge(b);
            if (kDebugMode) print("Sincronizado badge: \${b['nome_badge']} (Apagado: \${b['deleted_badge']})");
          }
        }

        // 5. Atualizar Badges Obtidos
        if (updates['badges_obtidos_updates'] != null) {
          final List<dynamic> obtidos = updates['badges_obtidos_updates'];
          for (var o in obtidos) {
            await _db.upsertBadgeObtido(o);
            if (kDebugMode) print("Sincronizado badge obtido: \${o['id_badge']}");
          }
        }

        // 6. Finalmente, guardar o novo Timestamp do servidor para as próximas chamadas
        await _db.updateLastSyncTimestamp(newServerTime);
        
        if (kDebugMode) {
          print("Sincronização concluída com sucesso! Novo Timestamp: \$newServerTime");
        }
      } else {
        if (kDebugMode) {
          print("Não há atualizações pendentes no servidor.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro durante a sincronização: \$e");
      }
    }
  }
}
*/