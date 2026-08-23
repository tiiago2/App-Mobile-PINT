import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../database/daos/perfil_dao.dart';
import '../database/sync_manager.dart';
import '../database/sync_helpers.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/searchbar_filter.dart';
import '../controllers/perfil_controller.dart';
import '../database/daos/assinaturas_dao.dart';
import '../database/daos/badges_assinatura_dao.dart';
import 'package:file_picker/file_picker.dart';
import '../database/remote/api_client.dart';

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

  List<int> _badgeIdsDisposicao = [];
  List<Map<String, dynamic>> _todosBadges = [];
  String? _fotoUrl;
  bool _isLoadingImage = false;

  void _adicionarBadge(int id) {
    if (_badgeIdsDisposicao.length < 4 && !_badgeIdsDisposicao.contains(id)) {
      setState(() {
        _badgeIdsDisposicao.add(id);
      });
    }
  }

  void _removerBadge(int id) {
    setState(() {
      _badgeIdsDisposicao.remove(id);
    });
  }

  ImageProvider? _obterImageProvider(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return NetworkImage(pathOrUrl);
    } else {
      return FileImage(File(pathOrUrl));
    }
  }

  Future<void> _escolherImagem() async {
    print('📍 [TRACK 1] A iniciar seleção de imagem...');
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.single.path == null) {
        debugPrint('⚠️ [Foto Perfil] Seleção de imagem cancelada.');
        print('📍 [TRACK 2.1] Seleção cancelada pelo utilizador.');
        return;
      }

      final filePath = result.files.single.path!;
      debugPrint('📁 [Foto Perfil] Imagem selecionada: $filePath');
      print('📍 [TRACK 2.2] Imagem selecionada com sucesso no caminho: $filePath');

      setState(() {
        _isLoadingImage = true;
      });

      final user = AuthController.instance.currentUser;
      final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);
      print('📍 [TRACK 3] A obter userId da sessão: $userId. A guardar localmente...');

      if (userId != null && userId > 0) {
        final localPath = await PerfilController.instance.atualizarFotoPerfilLocal(userId, filePath);
        print('📍 [TRACK 4] Caminho local guardado no SQLite: $localPath');

        setState(() {
          _fotoUrl = localPath;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil guardada localmente! Será sincronizada em segundo plano.')),
          );
        }
      } else {
        print('📍 [TRACK 3.1] userId inválido ou nulo. Upload abortado.');
      }
    } catch (e) {
      print('💥 [TRACK ERROR] Exceção apanhada ao escolher imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao escolher imagem: $e')),
        );
      }
    } finally {
      print('📍 [TRACK 5] A entrar no FINALLY - Desativar isLoadingImage');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  late TextEditingController _nomeController;
  late TextEditingController _areaController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  @override
  void initState() {
    super.initState();
    final user = AuthController.instance.currentUser;
    final profile = PerfilController.instance.perfilData;

    final nome = profile?['nome_user']?.toString() ?? user?['nome']?.toString() ?? user?['nome_user']?.toString() ?? '';
    final email = profile?['email']?.toString() ?? user?['email']?.toString() ?? '';
    final telefone = profile?['telefone']?.toString() ?? user?['telefone']?.toString() ?? '';
    final area = profile?['nome_area']?.toString() ?? '';

    _nomeController = TextEditingController(text: nome);
    _areaController = TextEditingController(text: area);
    _emailController = TextEditingController(text: email);
    _telefoneController = TextEditingController(text: telefone);

    _fotoUrl = profile?['imagem_perfil']?.toString() ??
        user?['foto']?.toString() ??
        user?['imagem_perfil']?.toString() ??
        mockPerfil['fotoUrl'];

    if (profile == null) {
      // Carregar dados de perfil de forma assíncrona se não estiverem na cache do controller
      PerfilController.instance.carregarDadosPerfil().then((_) {
        if (mounted) {
          setState(() {
            final p = PerfilController.instance.perfilData;
            _nomeController.text = p?['nome_user']?.toString() ?? _nomeController.text;
            _emailController.text = p?['email']?.toString() ?? _emailController.text;
            _telefoneController.text = p?['telefone']?.toString() ?? _telefoneController.text;
            _areaController.text = p?['nome_area']?.toString() ?? _areaController.text;
            _fotoUrl = p?['imagem_perfil']?.toString() ?? _fotoUrl;
            _badgeIdsDisposicao = List<int>.from(PerfilController.instance.signatureBadgeIds);
            _todosBadges = List<Map<String, dynamic>>.from(PerfilController.instance.conqueredBadges);
          });
        }
      });
    } else {
      _badgeIdsDisposicao = List<int>.from(PerfilController.instance.signatureBadgeIds);
      _todosBadges = List<Map<String, dynamic>>.from(PerfilController.instance.conqueredBadges);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _areaController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final user = AuthController.instance.currentUser;
      final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);
      
      if (userId != null && userId > 0) {
        final userArea = user?['area'];
        String? areaId;
        if (userArea is Map) {
          areaId = userArea['id_area']?.toString();
        }
        
        try {
          // Chamada unificada Offline-First no PerfilController (Dados Pessoais + Foto + Assinatura)
          await PerfilController.instance.guardarAlteracoesPerfilOffline(
            userId: userId,
            nome: _nomeController.text.trim(),
            email: _emailController.text.trim(),
            telefone: _telefoneController.text.trim(),
            idArea: user?['id_area']?.toString() ?? areaId,
            fotoLocalPath: _fotoUrl,
            assinaturaSourcePath: null, // Caso queira passar caminho físico de assinatura, se implementado futuramente
            badgeIdsDisposicao: _badgeIdsDisposicao,
          );

          // Agendar/Disparar Push Sync imediato em background
          SyncManager.instance.executePushSync(userId).catchError((e) {
            debugPrint('⚠️ [SyncManager] Erro no push sync automático ao editar perfil: $e');
            return false;
          });

        } catch (e) {
          debugPrint('❌ [EditarPerfil] Erro ao guardar dados locais: $e');
        }
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.perfilAtualizadoSucesso ?? 'Perfil atualizado com sucesso!')),
        );
        if (context.canPop()) {
          context.pop();
        }
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
                  child: GestureDetector(
                    onTap: _isLoadingImage ? null : _escolherImagem,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppCores.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(35.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _isLoadingImage
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppCores.azulFundo,
                                  ),
                                )
                              : (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                                  ? (_fotoUrl!.startsWith('http://') || _fotoUrl!.startsWith('https://'))
                                      ? Image.network(
                                          _fotoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/default_pint.jpg',
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : File(_fotoUrl!).existsSync()
                                          ? Image.file(
                                              File(_fotoUrl!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/default_pint.jpg',
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              'assets/images/default_pint.jpg',
                                              fit: BoxFit.cover,
                                            )
                                  : Image.asset(
                                      'assets/images/default_pint.jpg',
                                      fit: BoxFit.cover,
                                    ),
                        ),
                        if (!_isLoadingImage)
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
  final List<int> badgeIdsDisposicao;
  final List<Map<String, dynamic>> todosBadges;
  final Function(int) onAddBadge;
  final Function(int) onRemoveBadge;

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
        (badge) => intOrNull(badge['id']) == id,
        orElse: () => <String, dynamic>{},
      );
    }).where((badge) => badge.isNotEmpty).toList();

    // Filtra os restantes (que não estão em exposição)
    var restantes = widget.todosBadges.where((badge) {
      return !widget.badgeIdsDisposicao.contains(intOrNull(badge['id']));
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
            onTap: () => widget.onRemoveBadge(intOrNull(badge['id']) ?? 0),
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
                    onTap: () => widget.onAddBadge(intOrNull(badge['id']) ?? 0),
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