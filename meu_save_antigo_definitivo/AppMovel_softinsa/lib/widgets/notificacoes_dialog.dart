import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';

class NotificacoesDialog extends StatefulWidget {
  const NotificacoesDialog({super.key});

  @override
  State<NotificacoesDialog> createState() => _NotificacoesDialogState();
}

class _NotificacoesDialogState extends State<NotificacoesDialog> {
  int _selectedTab = 0; // 0: Notificações, 1: Avisos

  // Mock de notificações normais
  final List<Map<String, dynamic>> _mockNotificacoes = [
    {
      'descricao': 'Administrador atualizou o badge Low Code(júnior)',
      'tempo': 'há 2 horas',
      'isNova': true,
      'tipo': 'badge',
    },
    {
      'descricao': 'A sua candidatura em Low Code(júnior) foi aceite',
      'tempo': 'há 7 horas',
      'isNova': false,
      'tipo': 'aceite',
    },
    {
      'descricao': 'A sua candidatura em Low Code(Sénior) foi recusada',
      'tempo': 'há 1 dia',
      'isNova': false,
      'tipo': 'rejeitada',
    },
    {
      'descricao': 'A sua candidatura em Low Code(Intermédio) foi aceite',
      'tempo': 'há 1 mês',
      'isNova': false,
      'tipo': 'aceite',
    },
  ];

  // Mock de avisos
  final List<Map<String, dynamic>> _mockAvisos = [
    {
      'descricao': 'Manutenção programada do sistema no dia 28/07 das 02:00 às 04:00.',
      'tempo': 'há 1 dia',
      'isNova': true,
      'tipoDestino': 'Grupo',
      'destino': 'Todos os Consultores',
      'autor': 'Administrador',
    },
    {
      'descricao': 'Por favor, atualize o seu perfil e adicione os novos certificados obtidos.',
      'tempo': 'há 3 dias',
      'isNova': false,
      'tipoDestino': 'Individual',
      'destino': 'Tiago',
      'autor': 'Recursos Humanos',
    },
    {
      'descricao': 'Nova Service Line "Cloud & DevOps" disponível para candidaturas.',
      'tempo': 'há 5 dias',
      'isNova': false,
      'tipoDestino': 'Área',
      'destino': 'Cloud',
      'autor': 'Direção',
    },
  ];

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
    final dataStr = raw['tempo'];
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

    final listExibida = _selectedTab == 0 ? _mockNotificacoes : _mockAvisos;

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
                            final tempoStr = raw['tempo'] ?? '';
                            final isNova = raw['isNova'] ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10.0),
                                onTap: () {
                                  if (_selectedTab == 1) {
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
