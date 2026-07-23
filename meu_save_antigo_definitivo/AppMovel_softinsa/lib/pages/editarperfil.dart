import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/searchbar_filter.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, dynamic> mockPerfil = {
    'nome': 'João Silva',
    'area': 'Low Code',
    'email': 'joaosilva@gmail.com',
    'telefone': '+351 999 999 999',
    'fotoUrl': 'https://i.pravatar.cc/300?img=11',
  };

  List<String> _badgeIdsDisposicao = ['b1', 'b2', 'b3', 'b4'];
  final List<Map<String, dynamic>> _todosBadges = const [
    {'id': 'b1', 'nome': 'Low Code', 'imagem': 'https://i.pravatar.cc/300?img=12'},
    {'id': 'b2', 'nome': 'Outsystems', 'imagem': 'https://i.pravatar.cc/300?img=13'},
    {'id': 'b3', 'nome': 'Flutter', 'imagem': 'https://i.pravatar.cc/300?img=14'},
    {'id': 'b4', 'nome': 'AWS', 'imagem': 'https://i.pravatar.cc/300?img=15'},
    {'id': 'b5', 'nome': 'Scrum', 'imagem': 'https://i.pravatar.cc/300?img=16'},
    {'id': 'b6', 'nome': 'Java', 'imagem': 'https://i.pravatar.cc/300?img=17'},
  ];

  void _adicionarBadge(String id) {
    if (_badgeIdsDisposicao.length < 4 && !_badgeIdsDisposicao.contains(id)) {
      setState(() {
        _badgeIdsDisposicao.add(id);
      });
    }
  }

  void _removerBadge(String id) {
    setState(() {
      _badgeIdsDisposicao.remove(id);
    });
  }

  late TextEditingController _nomeController;
  late TextEditingController _areaController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: mockPerfil['nome']);
    _areaController = TextEditingController(text: mockPerfil['area']);
    _emailController = TextEditingController(text: mockPerfil['email']);
    _telefoneController = TextEditingController(text: mockPerfil['telefone']);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _areaController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      // Adicionar a lógica de gravação aqui no futuro
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.perfilAtualizadoSucesso ?? 'Perfil atualizado com sucesso!')),
      );
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0, // Sem sombra
        leading: IconButton(
          icon: Icon(UIcons.boldRounded.angle_small_left, color: AppCores.fontes, size: AppTamanhos.iconeNavegacao),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)?.editarPerfil ?? 'Editar Perfil',
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: AppTamanhos.titulo,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              UIcons.boldRounded.check,
              color: AppCores.fontes,
              size: AppTamanhos.iconeNavegacao,
            ),
            onPressed: _guardar,
          ),
          const TopBarActions(showDocumentIcon: false),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTamanhos.margemEcra),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppCores.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(35.0),
                          image: mockPerfil['fotoUrl'] != null
                              ? DecorationImage(
                                  image: NetworkImage(mockPerfil['fotoUrl']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: mockPerfil['fotoUrl'] == null
                            ? const Icon(Icons.person, size: 40, color: AppCores.fontes)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: AppCores.azulFundo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppCores.branco,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTamanhos.gapPerfil),
                _buildTextField(AppLocalizations.of(context)?.nome ?? 'Nome', _nomeController),
                const SizedBox(height: 16.0),
                _buildTextField(AppLocalizations.of(context)?.email ?? 'Email', _emailController, TextInputType.emailAddress),
                const SizedBox(height: 16.0),
                _buildTextField(AppLocalizations.of(context)?.telefone ?? 'Telefone', _telefoneController, TextInputType.phone),
                const SizedBox(height: 32.0),
                GerirBadgesSeccao(
                  badgeIdsDisposicao: _badgeIdsDisposicao,
                  todosBadges: _todosBadges,
                  onAddBadge: _adicionarBadge,
                  onRemoveBadge: _removerBadge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppCores.fontes),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppCores.fontes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.padrao),
          borderSide: const BorderSide(color: AppCores.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.padrao),
          borderSide: const BorderSide(color: AppCores.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.padrao),
          borderSide: const BorderSide(color: AppCores.azulFundo, width: 2.0),
        ),
        filled: true,
        fillColor: AppCores.branco,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          final l10n = AppLocalizations.of(context);
          return '${l10n?.porFavorInsira ?? 'Por favor, insira'} ${label.toLowerCase()}';
        }
        return null;
      },
    );
  }
}

class GerirBadgesSeccao extends StatefulWidget {
  final List<String> badgeIdsDisposicao;
  final List<Map<String, dynamic>> todosBadges;
  final Function(String) onAddBadge;
  final Function(String) onRemoveBadge;

  const GerirBadgesSeccao({
    super.key,
    required this.badgeIdsDisposicao,
    required this.todosBadges,
    required this.onAddBadge,
    required this.onRemoveBadge,
  });

  @override
  State<GerirBadgesSeccao> createState() => _GerirBadgesSeccaoState();
}

class _GerirBadgesSeccaoState extends State<GerirBadgesSeccao> {
  String _pesquisa = '';
  FilterOptions _filterOptions = const FilterOptions();

  @override
  Widget build(BuildContext context) {
    // Filtra os badges de exposição baseando-se nos IDs
    final List<Map<String, dynamic>> badgesExibicao = widget.badgeIdsDisposicao.map((id) {
      return widget.todosBadges.firstWhere(
        (badge) => badge['id'] == id,
        orElse: () => <String, dynamic>{},
      );
    }).where((badge) => badge.isNotEmpty).toList();

    // Filtra os restantes (que não estão em exposição)
    var restantes = widget.todosBadges.where((badge) {
      return !widget.badgeIdsDisposicao.contains(badge['id']);
    }).toList();

    // Apply search filter
    if (_pesquisa.isNotEmpty) {
      final query = _pesquisa.trim().toLowerCase();
      restantes = restantes.where((badge) {
        final title = (badge['titulo'] ?? badge['nome'] ?? '').toString().toLowerCase();
        final area = badge['area']?.toString().toLowerCase() ?? '';
        return title.contains(query) || area.contains(query);
      }).toList();
    }

    // Apply Level Filter
    if (_filterOptions.nivel != 'todos') {
      final String lvl = _filterOptions.nivel;
      restantes = restantes.where((b) {
        final nivelNome = (b['nivelNome'] ?? b['nivel'] ?? '').toString().toLowerCase();
        final title = (b['titulo'] ?? b['nome'] ?? '').toString().toLowerCase();
        if (lvl == 'basico') return nivelNome.contains('básico') || nivelNome.contains('basico') || title.contains('básico') || title.contains('basico') || title.contains('practitioner');
        if (lvl == 'intermedio') return nivelNome.contains('intermédio') || nivelNome.contains('intermedio') || title.contains('intermédio') || title.contains('intermedio') || title.contains('master');
        if (lvl == 'senior') return nivelNome.contains('sénior') || nivelNome.contains('senior') || title.contains('sénior') || title.contains('senior') || title.contains('pro') || title.contains('avançado') || title.contains('avancado');
        if (lvl == 'especialista') return nivelNome.contains('especialista') || title.contains('especialista');
        if (lvl == 'lider') return nivelNome.contains('líder') || nivelNome.contains('lider') || title.contains('líder') || title.contains('lider');
        return true;
      }).toList();
    }

    // Apply Type Filter
    if (_filterOptions.tipo != 'todos') {
      final String t = _filterOptions.tipo;
      restantes = restantes.where((b) {
        final isEspecial = b['especial'] == true || b['especial'] == '1';
        if (t == 'especial') return isEspecial;
        if (t == 'normal') return !isEspecial;
        return true;
      }).toList();
    }

    // Apply Service Line Filter
    if (_filterOptions.serviceLine != 'todos') {
      final String sl = _filterOptions.serviceLine;
      restantes = restantes.where((b) {
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? '').toString().toLowerCase();
        final area = (b['area'] ?? b['areaNome'] ?? b['category'] ?? '').toString().toLowerCase();
        if (sl == 'cloud') return area.contains('cloud') || title.contains('cloud') || title.contains('aws');
        if (sl == 'appdev') return area.contains('dev') || area.contains('low') || area.contains('design') || title.contains('flutter') || title.contains('java') || title.contains('scrum') || title.contains('outsystems');
        if (sl == 'enterprise') return title.contains('sap') || title.contains('salesforce') || title.contains('oracle');
        if (sl == 'security') return area.contains('security') || area.contains('segurança') || area.contains('cyber') || title.contains('security') || title.contains('segurança') || title.contains('cyber');
        return true;
      }).toList();
    }

    // Apply Learning Path Filter
    if (_filterOptions.learningPath != 'todos') {
      final String lp = _filterOptions.learningPath;
      restantes = restantes.where((b) {
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? '').toString().toLowerCase();
        final areaVal = (b['area'] ?? b['areaNome'] ?? b['category'] ?? '').toString().toLowerCase();
        if (lp == 'digital_innovation') return title.contains('digital') || title.contains('innovation');
        if (lp == 'cloud_solutions') return areaVal.contains('cloud') || title.contains('cloud') || title.contains('aws');
        if (lp == 'lowcode_agile') return areaVal.contains('low') || title.contains('low') || title.contains('outsystems') || title.contains('scrum');
        if (lp == 'cybersecurity') return areaVal.contains('security') || areaVal.contains('segurança') || areaVal.contains('cyber') || title.contains('security') || title.contains('segurança') || title.contains('cyber');
        if (lp == 'devops_agile') return areaVal.contains('dev') || title.contains('devops') || title.contains('agile');
        return true;
      }).toList();
    }

    // Apply Sorting
    restantes.sort((a, b) {
      final nameA = (a['titulo'] ?? a['nome'] ?? '').toString().toLowerCase();
      final nameB = (b['titulo'] ?? b['nome'] ?? '').toString().toLowerCase();
      final ptsA = int.tryParse((a['pontos'] ?? '0').toString()) ?? 0;
      final ptsB = int.tryParse((b['pontos'] ?? '0').toString()) ?? 0;

      if (_filterOptions.ordenarPor == 'nome_asc') {
        return nameA.compareTo(nameB);
      } else if (_filterOptions.ordenarPor == 'nome_desc') {
        return nameB.compareTo(nameA);
      } else if (_filterOptions.ordenarPor == 'pontos_asc') {
        return ptsA.compareTo(ptsB);
      } else if (_filterOptions.ordenarPor == 'pontos_desc') {
        return ptsB.compareTo(ptsA);
      }
      return 0;
    });

    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.badgesEmDisposicao ?? 'Badges em Disposição',
          style: const TextStyle(
            fontSize: AppTamanhos.titulo,
            color: AppCores.fontes,
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: badgesExibicao.map((badge) => _buildBadgeDisposicao(badge)).toList(),
        ),
        const SizedBox(height: 32.0),
        Text(
          l10n?.restantesBadges ?? 'Restantes Badges',
          style: const TextStyle(
            fontSize: AppTamanhos.titulo,
            color: AppCores.fontes,
          ),
        ),
        const SizedBox(height: 16.0),
        // A SearchBar existente no projeto
        SearchBarFilter(
          hintText: l10n?.pesquisarBadge ?? 'Pesquisar Badge...',
          onChanged: (value) {
            setState(() {
              _pesquisa = value;
            });
          },
          filterOptions: _filterOptions,
          onFilterChanged: (newOptions) {
            setState(() {
              _filterOptions = newOptions;
            });
          },
        ),
        const SizedBox(height: 24.0),
        Wrap(
          spacing: 16.0,
          runSpacing: 24.0,
          alignment: WrapAlignment.start,
          children: restantes.map((badge) => _buildBadgeRestante(badge)).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeDisposicao(Map<String, dynamic> badge) {
    final String imageUrl = badge['imagem'] ?? 'https://i.pravatar.cc/300?img=1';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppCores.outline.withValues(alpha: 0.3),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => widget.onRemoveBadge(badge['id']),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeRestante(Map<String, dynamic> badge) {
    final String imageUrl = badge['imagem'] ?? 'https://i.pravatar.cc/300?img=1';
    final String nome = badge['nome'] ?? 'Low Code';
    final bool canAdd = widget.badgeIdsDisposicao.length < 4;

    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCores.outline.withValues(alpha: 0.3),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (canAdd)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => widget.onAddBadge(badge['id']),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            nome,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}