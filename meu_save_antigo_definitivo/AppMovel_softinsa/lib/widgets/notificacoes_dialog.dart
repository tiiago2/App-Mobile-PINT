import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../database/daos/notificacao.dart';

class NotificacoesDialog extends StatefulWidget {
  const NotificacoesDialog({super.key});

  @override
  State<NotificacoesDialog> createState() => _NotificacoesDialogState();
}

class _NotificacoesDialogState extends State<NotificacoesDialog> {
  int _selectedTab = 0; // 0: Notificações, 1: Avisos
  List<Map<String, dynamic>> _notificacoesReais = [];
  List<Map<String, dynamic>> _avisosReais = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  String _formatarTempo(String? dataEnvioStr, String locale) {
    if (dataEnvioStr == null || dataEnvioStr.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(dataEnvioStr).toLocal();
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return locale == 'en' ? 'just now' : locale == 'es' ? 'ahora mesmo' : 'agora mesmo';
      } else if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return locale == 'en' ? '$m m ago' : locale == 'es' ? 'hace $m m' : 'há $m min';
      } else if (diff.inHours < 24) {
        final h = diff.inHours;
        return locale == 'en' ? '$h h ago' : locale == 'es' ? 'hace $h h' : 'há $h horas';
      } else if (diff.inDays < 30) {
        final d = diff.inDays;
        return locale == 'en' ? '$d d ago' : locale == 'es' ? 'hace $d d' : 'há $d dias';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (_) {}
    return dataEnvioStr.length > 10 ? dataEnvioStr.substring(0, 10) : dataEnvioStr;
  }

  Future<void> _carregarDados() async {
    try {
      final rows = await NotificacoesDao.instance.getNotificacoes();

      final List<Map<String, dynamic>> notificacoes = [];
      final List<Map<String, dynamic>> avisos = [];

      for (final row in rows) {
        final tipoNotif = row['tipo_notificacao']?.toString() ?? '';
        final desc = row['descricao_notificacao']?.toString() ?? '';
        final isNova = (row['lida'] ?? 0) == 0;
        final dataEnvio = row['data_envio']?.toString();
        final idNotif = row['id_notificacao'] as int? ?? 0;

        if (tipoNotif.toLowerCase().startsWith('aviso:')) {
          String tipoDestino = 'Geral';
          String destino = 'Todos';
          final parts = tipoNotif.split(':');
          if (parts.length >= 3) {
            final tDest = parts[1].toLowerCase();
            if (tDest == 'grupo') {
              tipoDestino = 'Grupo';
            } else if (tDest == 'individual') {
              tipoDestino = 'Individual';
            } else if (tDest == 'area') {
              tipoDestino = 'Área';
            }
            destino = parts[2];
          }

          String autor = 'Administrador';
          try {
            final jsonStr = row['notificacao_json'] as String?;
            if (jsonStr != null && jsonStr.isNotEmpty) {
              final Map<String, dynamic> decoded = jsonDecode(jsonStr);
              autor = decoded['autor'] ?? decoded['enviado_por'] ?? 'Administrador';
            }
          } catch (_) {}

          avisos.add({
            'id_notificacao': idNotif,
            'descricao': desc,
            'data_envio': dataEnvio,
            'isNova': isNova,
            'tipoDestino': tipoDestino,
            'destino': destino,
            'autor': autor,
            'raw': row,
          });
        } else {
          String tipoIcone = 'badge';
          if (tipoNotif == 'AVALIACAO_STATUS') {
            if (desc.toLowerCase().contains('aceite') || desc.toLowerCase().contains('aprovado')) {
              tipoIcone = 'aceite';
            } else {
              tipoIcone = 'rejeitada';
            }
          } else if (tipoNotif == 'BADGE_EXPIRADO') {
            tipoIcone = 'rejeitada';
          } else if (tipoNotif == 'AVISO_OBJETIVO') {
            tipoIcone = 'aviso_objetivo';
          }

          notificacoes.add({
            'id_notificacao': idNotif,
            'descricao': desc,
            'data_envio': dataEnvio,
            'isNova': isNova,
            'tipo': tipoIcone,
            'raw': row,
          });
        }
      }

      if (mounted) {
        setState(() {
          _notificacoesReais = notificacoes;
          _avisosReais = avisos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _obterIconeETempo(String tipo) {
    IconData iconData = UIcons.boldRounded.badge;
    Color color = AppCores.fontes;

    final lowerTipo = tipo.toLowerCase();
    if (lowerTipo == 'badge') {
      iconData = UIcons.boldRounded.badge;
      color = AppCores.fontes;
    } else if (lowerTipo == 'aceite') {
      iconData = Icons.verified_rounded;
      color = AppCores.sucessoLogin;
    } else if (lowerTipo == 'rejeitada') {
      iconData = Icons.warning_rounded;
      color = const Color(0xFFC40003);
    } else {
      iconData = UIcons.boldRounded.exclamation;
      color = const Color(0xFFE6900A);
    }

    return Icon(iconData, color: color, size: 20);
  }

  void _mostrarDetalheAviso(BuildContext context, Map<String, dynamic> raw) {
    final locale = Localizations.localeOf(context).languageCode;
    final dataStr = _formatarTempo(raw['data_envio'] ?? raw['tempo'], locale);
    final autor = raw['autor'] ?? 'Administrador';
    final mensagem = raw['descricao'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          title: Row(
            children: [
              Icon(
                UIcons.boldRounded.info,
                color: AppCores.fontes,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Comunicado',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppCores.fontes,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mensagem,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  color: AppCores.fontes,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppCores.outline, thickness: 1.0),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enviado por: $autor',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppCores.fontes,
                    ),
                  ),
                  Text(
                    dataStr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppCores.azulFundo,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obter traduções localizadas dinâmicas
    final locale = Localizations.localeOf(context).languageCode;
    String tabNotificacoes = "Notificações";
    String tabAvisos = "Avisos";
    String semNotificacoes = "Não tem notificações";
    String semAvisos = "Não existem avisos.";

    if (locale == 'en') {
      tabNotificacoes = "Notifications";
      tabAvisos = "Warnings";
      semNotificacoes = "No notifications";
      semAvisos = "No warnings.";
    } else if (locale == 'es') {
      tabNotificacoes = "Notificaciones";
      tabAvisos = "Avisos";
      semNotificacoes = "No tienes notificaciones";
      semAvisos = "No hay avisos.";
    }

    if (_isLoading) {
      return Material(
        type: MaterialType.transparency,
        child: Container(
          width: 320,
          height: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppCores.branco,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppCores.outline, width: 1.6),
          ),
          child: const CircularProgressIndicator(
            color: AppCores.azulFundo,
          ),
        ),
      );
    }

    final listExibida = _selectedTab == 0 ? _notificacoesReais : _avisosReais;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: AppCores.branco,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppCores.outline, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho com abas
            Row(
              children: [
                // Aba Notificações
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            tabNotificacoes,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _selectedTab == 0
                                  ? AppCores.azulFundo
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? AppCores.azulFundo
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(1.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Aba Avisos
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            tabAvisos,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _selectedTab == 1
                                  ? AppCores.azulFundo
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? AppCores.azulFundo
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(1.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppCores.outline, thickness: 1.2, height: 1.2),
            const SizedBox(height: 12),
            // Lista de Notificações / Avisos
            Flexible(
              child: listExibida.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          _selectedTab == 0 ? semNotificacoes : semAvisos,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: listExibida.map((raw) {
                            final descricao = raw['descricao'] ?? '';
                            final tempoStr = _formatarTempo(raw['data_envio'], locale);
                            final isNova = raw['isNova'] ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10.0),
                                onTap: () async {
                                  final idNotif = raw['id_notificacao'] as int?;
                                  if (idNotif != null && isNova) {
                                    await NotificacoesDao.instance.marcarComoLida(idNotif);
                                    _carregarDados();
                                  }
                                  if (context.mounted && _selectedTab == 1) {
                                    _mostrarDetalheAviso(context, raw);
                                  }
                                },
                                child: _NotificacaoItem(
                                  descricao: descricao,
                                  tempo: tempoStr,
                                  icone: _selectedTab == 0 ? _obterIconeETempo(raw['tipo'] ?? '') : const SizedBox.shrink(),
                                  isNova: isNova,
                                  isAviso: _selectedTab == 1,
                                  tipoDestino: raw['tipoDestino'],
                                  destino: raw['destino'],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificacaoItem extends StatelessWidget {
  final String descricao;
  final String tempo;
  final Widget icone;
  final bool isNova;
  final bool isAviso;
  final String? tipoDestino;
  final String? destino;

  const _NotificacaoItem({
    required this.descricao,
    required this.tempo,
    required this.icone,
    required this.isNova,
    this.isAviso = false,
    this.tipoDestino,
    this.destino,
  });

  @override
  Widget build(BuildContext context) {
    if (isAviso) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isNova ? const Color(0xFFF2FCFD) : AppCores.fundo2,
          border: Border.all(
            color: isNova ? const Color(0xFF80DCF0) : AppCores.outline,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Texto do aviso à esquerda
            Expanded(
              child: Text(
                descricao,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0,
                  color: AppCores.fontes,
                  fontWeight: isNova ? FontWeight.bold : FontWeight.normal,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Lado direito (Ícone e Data)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  UIcons.boldRounded.info,
                  color: AppCores.fontes,
                  size: 16,
                ),
                const SizedBox(height: 6),
                // Data por baixo
                Text(
                  tempo,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.0,
                    color: AppCores.fontes,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isNova ? const Color(0xFFF2FCFD) : AppCores.fundo2,
        border: Border.all(
          color: isNova ? const Color(0xFF80DCF0) : AppCores.outline,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bolinha de Não Lida (Alerta): #00B8E0
          if (isNova) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF00B8E0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Texto descritivo/título ao centro
          Expanded(
            child: Text(
              descricao,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0,
                color: AppCores.fontes,
                fontWeight: isNova ? FontWeight.bold : FontWeight.normal,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Lado direito (Ícone e Data por baixo)
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icone,
              const SizedBox(height: 6),
              if (tempo.isNotEmpty)
                Text(
                  tempo,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.0,
                    color: AppCores.fontes,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
