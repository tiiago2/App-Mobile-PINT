import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import '../controllers/auth_controller.dart';
import '../controllers/perfil_controller.dart';
import '../services/session_storage.dart';
import '../variaveis/variaveis.dart';
import '../variaveis/tipografia.dart';
import '../widgets/top_bar_actions.dart';
import '../idiomas/app_localizations.dart';
import 'badge_detalhe.dart';
import 'historico_badges.dart';

ImageProvider? _obterImageProvider(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return NetworkImage(pathOrUrl);
  } else {
    return FileImage(File(pathOrUrl));
  }
}

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final Map<String, dynamic> mockPerfil = const {
    'nome': 'João Silva',
    'area': 'Low Code',
    'cargo': 'Talent Manager',
    'email': 'joaosilva@gmail.com',
    'telefone': '+351 999 999 999',
    'fotoUrl': 'https://i.pravatar.cc/300?img=11',
  };

  final Map<String, dynamic> mockLearningPath = const {
    'titulo': 'Digital Innovation',
    'badgesConquistados': 12,
    'badgesTotal': 20,
  };

  final Map<String, dynamic> mockAssinatura = const {
    'badgeIds': [1, 2, 3, 4],
  };

  final List<Map<String, dynamic>> mockTodosBadges = const [
    {'id': 1, 'titulo': 'Cloud Básico', 'subtitulo': 'Cloud', 'imagem': 'https://i.pravatar.cc/300?img=11', 'dataAquisicao': '2026-05-20', 'validadeDias': 30, 'pontos': 150},
    {'id': 2, 'titulo': 'Low Code Básico', 'subtitulo': 'Low Code', 'imagem': 'https://i.pravatar.cc/300?img=12', 'dataAquisicao': '2026-06-17', 'validadeDias': 365, 'pontos': 150},
    {'id': 3, 'titulo': 'Champion Básico', 'subtitulo': 'Champion', 'imagem': 'https://i.pravatar.cc/300?img=13', 'dataAquisicao': '2025-10-10', 'pontos': 200},
    {'id': 4, 'titulo': 'Digital Básico', 'subtitulo': 'Digital', 'imagem': 'https://i.pravatar.cc/300?img=14', 'dataAquisicao': '2026-01-05', 'validadeDias': 90, 'pontos': 100},
    {'id': 5, 'titulo': 'Design Básico', 'subtitulo': 'Design', 'imagem': 'https://i.pravatar.cc/300?img=15', 'dataAquisicao': '2026-07-01', 'pontos': 50},
    {'id': 6, 'titulo': 'DevOps Básico', 'subtitulo': 'DevOps', 'imagem': 'https://i.pravatar.cc/300?img=16', 'dataAquisicao': '2026-04-20', 'validadeDias': 120, 'pontos': 250},
    {'id': 7, 'titulo': 'Security Básico', 'subtitulo': 'Security', 'imagem': 'https://i.pravatar.cc/300?img=17', 'dataAquisicao': '2024-11-20', 'pontos': 300},
    {'id': 8, 'titulo': 'Agile Básico', 'subtitulo': 'Agile', 'imagem': 'https://i.pravatar.cc/300?img=18', 'dataAquisicao': '2026-04-15', 'pontos': 120},
    {'id': 9, 'titulo': 'Data Básico', 'subtitulo': 'Data', 'imagem': 'https://i.pravatar.cc/300?img=19', 'dataAquisicao': '2025-05-01', 'validadeDias': 30, 'pontos': 180},
    {'id': 10, 'titulo': 'AI Básico', 'subtitulo': 'AI', 'imagem': 'https://i.pravatar.cc/300?img=20', 'dataAquisicao': '2026-06-10', 'pontos': 400},
  ];

  final List<int> mockGaleriaIds = const [2, 1, 3, 4];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerfilController.instance.carregarDadosPerfil();
    });
  }

  Future<void> _mostrarConfirmacaoLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppCores.branco,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppEspacamentos.logoutDialogMargemHorizontal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.padrao),
            side: const BorderSide(
              color: AppCores.outline,
              width: AppBorders.espessuraPrincipal,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTamanhos.logoutDialogLarguraMaxima,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppEspacamentos.logoutDialogPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.logoutTitulo,
                    style: AppTipografia.logoutDialogTitulo,
                  ),
                  const SizedBox(
                    height: AppEspacamentos.logoutDialogGapTituloMensagem,
                  ),
                  Text(
                    l10n.logoutMensagem,
                    style: AppTipografia.logoutDialogMensagem,
                  ),
                  const SizedBox(
                    height: AppEspacamentos.logoutDialogGapAcoes,
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final empilharAcoes = constraints.maxWidth <
                          AppTamanhos.logoutDialogLarguraEmpilharAcoes;
                      final cancelar = _LogoutCancelarButton(
                        text: l10n.logoutCancelar,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      );
                      final confirmar = _LogoutConfirmarButton(
                        text: l10n.logoutConfirmar,
                        onPressed: () async {
                          try {
                            await AuthController.instance.logout();

                            if (!dialogContext.mounted || !context.mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop();
                            context.go('/login');
                          } on SessionStorageException {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.authErroGenerico),
                                ),
                              );
                            }
                          }
                        },
                      );

                      if (empilharAcoes) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            cancelar,
                            const SizedBox(
                              height: AppEspacamentos
                                  .logoutDialogGapEntreBotoes,
                            ),
                            confirmar,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cancelar),
                          const SizedBox(
                            width: AppEspacamentos.logoutDialogGapEntreBotoes,
                          ),
                          Expanded(child: confirmar),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _lerString(
    Map<String, dynamic>? origem,
    String chave,
    String fallback,
  ) {
    final valor = origem?[chave];

    if (valor is String && valor.trim().isNotEmpty) {
      return valor;
    }

    return fallback;
  }

  Map<String, dynamic>? _lerMapa(
    Map<String, dynamic>? origem,
    String chave,
  ) {
    final valor = origem?[chave];

    return valor is Map<String, dynamic> ? valor : null;
  }

  String _lerStringAninhada(
    Map<String, dynamic>? origem,
    String chaveMapa,
    String chaveValor,
    String fallback,
  ) {
    return _lerString(_lerMapa(origem, chaveMapa), chaveValor, fallback);
  }

  String? _lerUrlOuNull(
    Map<String, dynamic>? origem,
    String chave,
  ) {
    final valor = origem?[chave];

    if (valor is String && valor.trim().isNotEmpty) {
      return valor;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authController = AuthController.instance;
    final perfilController = PerfilController.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([authController, perfilController]),
      builder: (context, _) {
        final profile = perfilController.perfilData;
        final lp = perfilController.learningPathProgress;

        final nome = profile?['nome_user']?.toString() ??
            _lerString(authController.currentUser, 'nome', mockPerfil['nome'] as String);

        final email = profile?['email']?.toString() ??
            _lerString(authController.currentUser, 'email', mockPerfil['email'] as String);

        final telefone = profile?['telefone']?.toString() ??
            _lerString(authController.currentUser, 'telefone', mockPerfil['telefone'] as String);

        final area = profile?['nome_area']?.toString() ??
            _lerStringAninhada(authController.currentUser, 'area', 'nome', mockPerfil['area'] as String);

        final learningPathTitulo = lp?['titulo']?.toString() ??
            _lerStringAninhada(authController.currentUser, 'learningPath', 'nome', mockLearningPath['titulo'] as String);

        final badgesConquistados = lp?['badgesConquistados'] as int? ?? 0;
        final badgesTotal = lp?['badgesTotal'] as int? ?? 0;

        final cargoAssinatura = area;

        final fotoUrl = profile?['imagem_perfil']?.toString() ??
            _lerUrlOuNull(authController.currentUser, 'foto') ??
            _lerUrlOuNull(authController.currentUser, 'imagem_perfil') ??
            (mockPerfil['fotoUrl'] as String?);

        return Scaffold(
          backgroundColor: AppCores.branco,
          appBar: AppBar(
            backgroundColor: AppCores.branco,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            titleSpacing: AppTamanhos.colocacao_titulo,
            title: Text(
              AppLocalizations.of(context)?.perfilTitulo ?? 'Perfil Pessoal',
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: AppTamanhos.titulo,
              ),
            ),
            actions: [
              TopBarActions(
                showLogoutIcon: true,
                showDocumentIcon: true,
                onLogoutPressed: () => _mostrarConfirmacaoLogout(context),
              ),
            ],
          ),
          body: perfilController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTamanhos.margemEcra),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          CartaoPerfil(
                            nome: nome,
                            area: area,
                            email: email,
                            telefone: telefone,
                            fotoUrl: fotoUrl,
                          ),
                          SizedBox(height: AppTamanhos.gapPerfil),
                          CartaoLearningPath(
                            titulo: learningPathTitulo,
                            badgesConquistados: badgesConquistados,
                            badgesTotal: badgesTotal,
                          ),
                          SizedBox(height: AppTamanhos.gapPerfil),
                          CartaoAssinatura(
                            nome: nome,
                            cargo: cargoAssinatura,
                            email: email,
                            telefone: telefone,
                            badgeIds: perfilController.signatureBadgeIds,
                            todosBadges: perfilController.conqueredBadges,
                          ),
                          SizedBox(height: AppTamanhos.gapPerfil),
                          CartaoGaleriaBadges(
                            todosBadges: perfilController.conqueredBadges,
                          ),
                          SizedBox(height: AppTamanhos.gapPerfil),
                          CartaoHistoricoBadges(
                            todosBadges: perfilController.historyBadges,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _LogoutCancelarButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _LogoutCancelarButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(AppTamanhos.logoutDialogAlturaBotao),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppEspacamentos.logoutDialogPaddingBotaoHorizontal,
          ),
        ),
        backgroundColor: const WidgetStatePropertyAll(AppCores.branco),
        foregroundColor: const WidgetStatePropertyAll(AppCores.azulFundo),
        overlayColor: const WidgetStatePropertyAll(AppCores.focoLogin),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.loginCampo),
          ),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(
            color: AppCores.azulFundo,
            width: AppBorders.espessuraPrincipal,
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTipografia.logoutDialogBotaoCancelar,
      ),
    );
  }
}

class _LogoutConfirmarButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _LogoutConfirmarButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(AppTamanhos.logoutDialogAlturaBotao),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppEspacamentos.logoutDialogPaddingBotaoHorizontal,
          ),
        ),
        backgroundColor: const WidgetStatePropertyAll(AppCores.erroLogin),
        foregroundColor: const WidgetStatePropertyAll(AppCores.branco),
        overlayColor: WidgetStatePropertyAll(
          AppCores.branco.withValues(alpha: 0.16),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.loginCampo),
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTipografia.logoutDialogBotaoConfirmar,
      ),
    );
  }
}

class CartaoPerfil extends StatelessWidget {
  final String nome;
  final String area;
  final String email;
  final String telefone;
  final String? fotoUrl;

  const CartaoPerfil({
    super.key,
    required this.nome,
    required this.area,
    required this.email,
    required this.telefone,
    this.fotoUrl,
  });

  Widget _buildCampo(String label, String valor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14.0, color: AppCores.fontes),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: valor,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppCores.outline.withOpacity(0.3),
            borderRadius: BorderRadius.circular(35.0),
            image: fotoUrl != null
                ? DecorationImage(
                    image: _obterImageProvider(fotoUrl)!,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: fotoUrl == null
              ? const Icon(Icons.person, size: 40, color: AppCores.fontes)
              : null,
        ),
        const SizedBox(width: 24.0),
        // Detalhes
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCampo('Nome', nome),
              const SizedBox(height: 8.0),
              _buildCampo('Área', area),
              const SizedBox(height: 8.0),
              _buildCampo('Email', email),
              const SizedBox(height: 8.0),
              _buildCampo('Telefone', telefone),
            ],
          ),
        ),
      ],
    );
  }
}

class CartaoLearningPath extends StatelessWidget {
  final String titulo;
  final int badgesConquistados;
  final int badgesTotal;

  const CartaoLearningPath({
    super.key,
    required this.titulo,
    required this.badgesConquistados,
    required this.badgesTotal,
  });

  @override
  Widget build(BuildContext context) {
    // Cálculo dinâmico da percentagem de progresso
    final double progresso = badgesTotal == 0
        ? 0.0
        : badgesConquistados / badgesTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 19.0, vertical: 17.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF39639C), Color(0xFF4A7FC7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppBorders.padrao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learning Path',
                    style: TextStyle(color: Color(0xFFE8EDF3), fontSize: 12.0),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppCores.branco,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                UIcons.boldRounded.badge,
                color: AppCores.branco,
                size: 32.0,
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$badgesConquistados/$badgesTotal Badges',
                style: const TextStyle(color: AppCores.branco, fontSize: 12.0),
              ),
              Text(
                '${(progresso * 100).toInt()}%',
                style: const TextStyle(color: AppCores.branco, fontSize: 12.0),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(50.0),
            child: LinearProgressIndicator(
              value: progresso,
              backgroundColor: AppCores.fundo2.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppCores.branco),
              minHeight: 8.0,
            ),
          ),
        ],
      ),
    );
  }
}

class CartaoAssinatura extends StatelessWidget {
  final String nome;
  final String cargo;
  final String email;
  final String telefone;
  final List<int> badgeIds;
  final List<Map<String, dynamic>> todosBadges;

  const CartaoAssinatura({
    super.key,
    required this.nome,
    required this.cargo,
    required this.email,
    required this.telefone,
    required this.badgeIds,
    required this.todosBadges,
  });

  Widget _buildBadgeImage(int id) {
    // Procura o badge pelo ID na lista total de badges
    final badgeInfo = todosBadges.firstWhere(
      (badge) => badge['id'] == id,
      orElse: () => <String, dynamic>{},
    );

    final String? imageUrl = badgeInfo.containsKey('imagem')
        ? badgeInfo['imagem']
        : null;

    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppCores.outline.withOpacity(0.3),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? const Center(
              child: Icon(
                Icons.image_not_supported,
                color: AppCores.fontes,
                size: 24.0,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título e Ícone de Edição
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)?.assinaturaPessoal ?? 'Assinatura Pessoal',
              style: const TextStyle(
                fontSize: AppTamanhos.titulo,
                color: AppCores.fontes,
              ),
            ),
            IconButton(
              icon: Icon(UIcons.boldRounded.pencil, size: 20, color: AppCores.fontes),
              onPressed: () {
                context.push('/editarperfil');
              },
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        // Cartão Preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppCores.fundo2,
            borderRadius: BorderRadius.circular(AppBorders.padrao),
            border: Border.all(color: AppCores.outline),
          ),
          child: Column(
            children: [
              Text(
                '$nome | $cargo',
                style: const TextStyle(color: AppCores.fontes, fontSize: 10.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),
              Text(
                '$email | $telefone',
                style: const TextStyle(color: AppCores.fontes, fontSize: 10.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: badgeIds.map((id) => _buildBadgeImage(id)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CartaoGaleriaBadges extends StatelessWidget {
  final List<Map<String, dynamic>> todosBadges;

  const CartaoGaleriaBadges({
    super.key,
    required this.todosBadges,
  });

  Widget _buildBadgeItem(BuildContext context, Map<String, dynamic> badgeInfo) {
    final String? imageUrl = badgeInfo['imagem'];
    final String titulo = badgeInfo['titulo'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetalheScreen(
              badge: {
                ...badgeInfo,
                'estado': 'conquistados',
              },
            ),
          ),
        );
      },
      child: Container(
        width: 90,
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppCores.outline.withOpacity(0.3),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              titulo,
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 14.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)?.badgesPessoais ?? 'Badges Pessoais',
              style: const TextStyle(
                fontSize: AppTamanhos.titulo,
                color: AppCores.fontes,
              ),
            ),
            ElevatedButton(
              onPressed: () {context.push('/badgespessoais');},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppCores.fundo2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorders.padrao),
                ),
                side: const BorderSide(
                  width: 1.0,
                  color: AppCores.outline,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)?.verMais ?? 'Ver Mais',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16.0,
            runSpacing: 16.0,
            children: todosBadges.take(9).map((badgeInfo) => _buildBadgeItem(context, badgeInfo)).toList(),
          ),
        ),
      ],
    );
  }
}

class CartaoHistoricoBadges extends StatelessWidget {
  final List<Map<String, dynamic>> todosBadges;

  const CartaoHistoricoBadges({
    super.key,
    required this.todosBadges,
  });

  Widget _buildHistoricoItem(BuildContext context, Map<String, dynamic> badgeInfo) {
    final String? imageUrl = badgeInfo['imagem'];
    final String titulo = badgeInfo['titulo'] ?? '';
    final String subtitulo = badgeInfo['subtitulo'] ?? '';
    final int pontos = badgeInfo['pontos'] ?? 0;
    final String textoData = badgeInfo['textoData'] ?? '';
    final Color corData = badgeInfo['corData'] ?? AppCores.fontes;

    final estado = textoData.contains('Expirado') ? 'expirado' : 'conquistado';
    final badgeMap = {
      ...badgeInfo,
      'estado': estado,
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetalheScreen(badge: badgeMap),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppCores.outline.withValues(alpha: 0.3),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppCores.fontes,
                        size: 24.0,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppCores.fontes,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Color(0xFF767676), // Cinza para o subtítulo
                      fontSize: 12.0,
                    ),
                  ),
                  if (textoData.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        textoData,
                        style: TextStyle(
                          color: corData,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFF39639C),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_outlined, // Ícone de graduação/pontos
                    color: AppCores.branco,
                    size: 14.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '$pontos pts',
                    style: const TextStyle(
                      color: AppCores.branco,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final badgesOrdenados = todosBadges.map((b) {
      final String? dataAquisicaoStr = b['dataAquisicao'];
      if (dataAquisicaoStr == null) return null;
      
      final dataAquisicao = DateTime.parse(dataAquisicaoStr);
      DateTime dataRelevante = dataAquisicao;
      String textoData = 'Conquistado a $dataAquisicaoStr';
      Color corData = const Color(0xFF1E5FF5); // Azul
      
      final int? validadeDias = b['validadeDias'];
      if (validadeDias != null) {
        final dataExpiracao = dataAquisicao.add(Duration(days: validadeDias));
        if (dataExpiracao.isBefore(hoje)) {
          dataRelevante = dataExpiracao;
          textoData = 'Expirado a ${dataExpiracao.toString().substring(0, 10)}';
          corData = const Color(0xFFC41230); // Vermelho
        }
      }

      return {
        ...b,
        'dataRelevante': dataRelevante,
        'textoData': textoData,
        'corData': corData,
      };
    }).where((b) => b != null).cast<Map<String, dynamic>>().toList();

    badgesOrdenados.sort((a, b) {
      return (b['dataRelevante'] as DateTime).compareTo(a['dataRelevante'] as DateTime);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)?.historicoBadges ?? 'Histórico de Badges',
              style: const TextStyle(
                fontSize: AppTamanhos.titulo,
                color: AppCores.fontes,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoricoBadgesScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppCores.fundo2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorders.padrao),
                ),
                side: const BorderSide(
                  width: 1.0,
                  color: AppCores.outline,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)?.verMais ?? 'Ver Mais',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Container(
          decoration: BoxDecoration(
            color: AppCores.fundo2,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppCores.outline),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badgesOrdenados.length > 3 ? 3 : badgesOrdenados.length, // Limite de 3 para não ocupar todo o ecrã
            itemBuilder: (context, index) {
              return _buildHistoricoItem(context, badgesOrdenados[index]);
            },
          ),
        ),
      ],
    );
  }
}
