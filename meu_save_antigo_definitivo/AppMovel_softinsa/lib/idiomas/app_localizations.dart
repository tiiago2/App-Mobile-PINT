import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'idiomas/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @portugues.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get portugues;

  /// No description provided for @espanhol.
  ///
  /// In pt, this message translates to:
  /// **'Espanhol'**
  String get espanhol;

  /// No description provided for @ingles.
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get ingles;

  /// No description provided for @lingua.
  ///
  /// In pt, this message translates to:
  /// **'Língua'**
  String get lingua;

  /// No description provided for @notificacoesTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificacoesTitulo;

  /// No description provided for @candidaturasTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Candidaturas'**
  String get candidaturasTitulo;

  /// No description provided for @totalPontos.
  ///
  /// In pt, this message translates to:
  /// **'Total de Pontos Conquistados'**
  String get totalPontos;

  /// No description provided for @pts.
  ///
  /// In pt, this message translates to:
  /// **'pts'**
  String get pts;

  /// No description provided for @pesquisarBadge.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar Badge...'**
  String get pesquisarBadge;

  /// No description provided for @todos.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get todos;

  /// No description provided for @conquistados.
  ///
  /// In pt, this message translates to:
  /// **'Conquistados'**
  String get conquistados;

  /// No description provided for @concluidos.
  ///
  /// In pt, this message translates to:
  /// **'Concluídos'**
  String get concluidos;

  /// No description provided for @expirados.
  ///
  /// In pt, this message translates to:
  /// **'Expirados'**
  String get expirados;

  /// No description provided for @recusados.
  ///
  /// In pt, this message translates to:
  /// **'Recusados'**
  String get recusados;

  /// No description provided for @pendentes.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get pendentes;

  /// No description provided for @emProgresso.
  ///
  /// In pt, this message translates to:
  /// **'Em Progresso'**
  String get emProgresso;

  /// No description provided for @aprovado.
  ///
  /// In pt, this message translates to:
  /// **'Aprovado'**
  String get aprovado;

  /// No description provided for @pendente.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get pendente;

  /// No description provided for @recusado.
  ///
  /// In pt, this message translates to:
  /// **'Recusado'**
  String get recusado;

  /// No description provided for @expirado.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get expirado;

  /// No description provided for @completo.
  ///
  /// In pt, this message translates to:
  /// **'Completo'**
  String get completo;

  /// No description provided for @badgeExpiradoAlert.
  ///
  /// In pt, this message translates to:
  /// **'Este badge expirou e precisa ser renovado'**
  String get badgeExpiradoAlert;

  /// No description provided for @authLoginTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar sessão'**
  String get authLoginTitulo;

  /// No description provided for @authLoginSubtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Acede à tua plataforma de badges'**
  String get authLoginSubtitulo;

  /// No description provided for @authLoginEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get authLoginEmail;

  /// No description provided for @authLoginPassword.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe'**
  String get authLoginPassword;

  /// No description provided for @authLoginPasswordMostrar.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar'**
  String get authLoginPasswordMostrar;

  /// No description provided for @authLoginPasswordOcultar.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar'**
  String get authLoginPasswordOcultar;

  /// No description provided for @authLoginEntrar.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get authLoginEntrar;

  /// No description provided for @authLoginLoading.
  ///
  /// In pt, this message translates to:
  /// **'A validar credenciais...'**
  String get authLoginLoading;

  /// No description provided for @authLoginErro.
  ///
  /// In pt, this message translates to:
  /// **'Credenciais inválidas. Verifica o email e a palavra-passe.'**
  String get authLoginErro;

  /// No description provided for @authLoginEsqueciPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceste-te da palavra-passe?'**
  String get authLoginEsqueciPassword;

  /// No description provided for @authVoltarLogin.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao início de sessão'**
  String get authVoltarLogin;

  /// No description provided for @authRecuperarTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Alterar palavra-passe'**
  String get authRecuperarTitulo;

  /// No description provided for @authRecuperarSubtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Define uma nova palavra-passe para a tua conta'**
  String get authRecuperarSubtitulo;

  /// No description provided for @authNovaPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova palavra-passe'**
  String get authNovaPassword;

  /// No description provided for @authConfirmarPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar palavra-passe'**
  String get authConfirmarPassword;

  /// No description provided for @authRecuperarBotao.
  ///
  /// In pt, this message translates to:
  /// **'Alterar palavra-passe'**
  String get authRecuperarBotao;

  /// No description provided for @authPrimeiroAcessoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro acesso'**
  String get authPrimeiroAcessoTitulo;

  /// No description provided for @authPrimeiroAcessoSubtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Define a tua palavra-passe para começares'**
  String get authPrimeiroAcessoSubtitulo;

  /// No description provided for @authPrimeiroAcessoBotao.
  ///
  /// In pt, this message translates to:
  /// **'Guardar e continuar'**
  String get authPrimeiroAcessoBotao;

  /// No description provided for @authAceitarPoliticas.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito a Política de Privacidade e os Termos de Utilização'**
  String get authAceitarPoliticas;

  /// No description provided for @authCampoObrigatorio.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório.'**
  String get authCampoObrigatorio;

  /// No description provided for @authEmailInvalido.
  ///
  /// In pt, this message translates to:
  /// **'Introduz um email válido.'**
  String get authEmailInvalido;

  /// No description provided for @authPasswordsDiferentes.
  ///
  /// In pt, this message translates to:
  /// **'As palavras-passe não coincidem.'**
  String get authPasswordsDiferentes;

  /// No description provided for @authPoliticasObrigatorias.
  ///
  /// In pt, this message translates to:
  /// **'Tens de aceitar a Política de Privacidade e os Termos de Utilização.'**
  String get authPoliticasObrigatorias;

  /// No description provided for @authErroLigacao.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ligar ao servidor. Verifica a ligação e tenta novamente.'**
  String get authErroLigacao;

  /// No description provided for @authErroGenerico.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro. Tenta novamente.'**
  String get authErroGenerico;

  /// No description provided for @authLoginCredenciaisInvalidas.
  ///
  /// In pt, this message translates to:
  /// **'Email ou palavra-passe incorretos.'**
  String get authLoginCredenciaisInvalidas;

  /// No description provided for @authRecuperarSucesso.
  ///
  /// In pt, this message translates to:
  /// **'A tua palavra-passe foi redefinida com sucesso.'**
  String get authRecuperarSucesso;

  /// No description provided for @authPrimeiroAcessoSucesso.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe definida com sucesso. Já podes iniciar sessão.'**
  String get authPrimeiroAcessoSucesso;

  /// No description provided for @authConfirmar.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get authConfirmar;

  /// No description provided for @logoutTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Terminar sessão'**
  String get logoutTitulo;

  /// No description provided for @logoutMensagem.
  ///
  /// In pt, this message translates to:
  /// **'Tens a certeza de que pretendes terminar a sessão?'**
  String get logoutMensagem;

  /// No description provided for @logoutCancelar.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get logoutCancelar;

  /// No description provided for @logoutConfirmar.
  ///
  /// In pt, this message translates to:
  /// **'Terminar sessão'**
  String get logoutConfirmar;

  /// No description provided for @homeBomDia.
  ///
  /// In pt, this message translates to:
  /// **'Bom Dia!'**
  String get homeBomDia;

  /// No description provided for @homeBoaTarde.
  ///
  /// In pt, this message translates to:
  /// **'Boa Tarde!'**
  String get homeBoaTarde;

  /// No description provided for @homeBoaNoite.
  ///
  /// In pt, this message translates to:
  /// **'Boa Noite!'**
  String get homeBoaNoite;

  /// No description provided for @objetivosPropostos.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos Propostos:'**
  String get objetivosPropostos;

  /// No description provided for @badgesEmProgresso.
  ///
  /// In pt, this message translates to:
  /// **'Badges em Progresso:'**
  String get badgesEmProgresso;

  /// No description provided for @classificacaoGeral.
  ///
  /// In pt, this message translates to:
  /// **'Classificação Geral:'**
  String get classificacaoGeral;

  /// No description provided for @politicasRgpd.
  ///
  /// In pt, this message translates to:
  /// **'Políticas RGPD'**
  String get politicasRgpd;

  /// No description provided for @objetivosTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos de Badges'**
  String get objetivosTitulo;

  /// No description provided for @abaAtivos.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get abaAtivos;

  /// No description provided for @abaExpirados.
  ///
  /// In pt, this message translates to:
  /// **'Expirados'**
  String get abaExpirados;

  /// No description provided for @nenhumObjetivoAtivo.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum objetivo ativo.'**
  String get nenhumObjetivoAtivo;

  /// No description provided for @nenhumObjetivoExpirado.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum objetivo expirado.'**
  String get nenhumObjetivoExpirado;

  /// No description provided for @historicoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Badges'**
  String get historicoTitulo;

  /// No description provided for @abaCronologia.
  ///
  /// In pt, this message translates to:
  /// **'Cronologia'**
  String get abaCronologia;

  /// No description provided for @abaEstatisticas.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get abaEstatisticas;

  /// No description provided for @verMais.
  ///
  /// In pt, this message translates to:
  /// **'Ver Mais'**
  String get verMais;

  /// No description provided for @sugeridos.
  ///
  /// In pt, this message translates to:
  /// **'Sugeridos'**
  String get sugeridos;

  /// No description provided for @todosOsBadges.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Badges'**
  String get todosOsBadges;

  /// No description provided for @perfilTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Perfil Pessoal'**
  String get perfilTitulo;

  /// No description provided for @editarPerfil.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get editarPerfil;

  /// No description provided for @assinaturaPessoal.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura Pessoal'**
  String get assinaturaPessoal;

  /// No description provided for @badgesPessoais.
  ///
  /// In pt, this message translates to:
  /// **'Badges Pessoais'**
  String get badgesPessoais;

  /// No description provided for @historicoBadges.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Badges'**
  String get historicoBadges;

  /// No description provided for @badgesEspeciais.
  ///
  /// In pt, this message translates to:
  /// **'BADGES ESPECIAIS'**
  String get badgesEspeciais;

  /// No description provided for @minhaArea.
  ///
  /// In pt, this message translates to:
  /// **'A MINHA ÁREA'**
  String get minhaArea;

  /// No description provided for @outrasAreas.
  ///
  /// In pt, this message translates to:
  /// **'OUTRAS ÁREAS'**
  String get outrasAreas;

  /// No description provided for @distribuicaoBadges.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição de Badges'**
  String get distribuicaoBadges;

  /// No description provided for @badgesPorNivel.
  ///
  /// In pt, this message translates to:
  /// **'Badges Conquistados (por nível)'**
  String get badgesPorNivel;

  /// No description provided for @evolucaoBadges.
  ///
  /// In pt, this message translates to:
  /// **'Evolução de Badges'**
  String get evolucaoBadges;

  /// No description provided for @evolucaoPontos.
  ///
  /// In pt, this message translates to:
  /// **'Evolução de Pontos'**
  String get evolucaoPontos;

  /// No description provided for @detalheBadge.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe do Badge'**
  String get detalheBadge;

  /// No description provided for @voltar.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get voltar;

  /// No description provided for @especial.
  ///
  /// In pt, this message translates to:
  /// **'Especial'**
  String get especial;

  /// No description provided for @normal.
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @dias.
  ///
  /// In pt, this message translates to:
  /// **'dias'**
  String get dias;

  /// No description provided for @badgeConquistado.
  ///
  /// In pt, this message translates to:
  /// **'Badge conquistado'**
  String get badgeConquistado;

  /// No description provided for @badgeConquistadoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Conquista concluída com sucesso.'**
  String get badgeConquistadoDesc;

  /// No description provided for @candidaturaAnalise.
  ///
  /// In pt, this message translates to:
  /// **'Candidatura em análise'**
  String get candidaturaAnalise;

  /// No description provided for @candidaturaAnaliseDesc.
  ///
  /// In pt, this message translates to:
  /// **'A candidatura está a aguardar análise.'**
  String get candidaturaAnaliseDesc;

  /// No description provided for @candidaturaProgresso.
  ///
  /// In pt, this message translates to:
  /// **'Candidatura em progresso'**
  String get candidaturaProgresso;

  /// No description provided for @candidaturaRecusada.
  ///
  /// In pt, this message translates to:
  /// **'Candidatura recusada'**
  String get candidaturaRecusada;

  /// No description provided for @candidaturaRecusadaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Revê os requisitos antes de voltar a candidatar-te.'**
  String get candidaturaRecusadaDesc;

  /// No description provided for @badgeExpirado.
  ///
  /// In pt, this message translates to:
  /// **'Badge expirado'**
  String get badgeExpirado;

  /// No description provided for @badgeExpiradoDesc.
  ///
  /// In pt, this message translates to:
  /// **'A validade deste badge terminou.'**
  String get badgeExpiradoDesc;

  /// No description provided for @badgeDisponivel.
  ///
  /// In pt, this message translates to:
  /// **'Badge disponível'**
  String get badgeDisponivel;

  /// No description provided for @badgeDisponivelDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não iniciaste candidatura para este badge.'**
  String get badgeDisponivelDesc;

  /// No description provided for @requisitosEvidencias.
  ///
  /// In pt, this message translates to:
  /// **'Requisitos e evidências'**
  String get requisitosEvidencias;

  /// No description provided for @requisitosPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Os requisitos deste badge aparecerão aqui quando disponíveis.'**
  String get requisitosPlaceholder;

  /// No description provided for @selecionarAno.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar ano'**
  String get selecionarAno;

  /// No description provided for @badgesEmDisposicao.
  ///
  /// In pt, this message translates to:
  /// **'Badges em Disposição'**
  String get badgesEmDisposicao;

  /// No description provided for @restantesBadges.
  ///
  /// In pt, this message translates to:
  /// **'Restantes Badges'**
  String get restantesBadges;

  /// No description provided for @perfilAtualizadoSucesso.
  ///
  /// In pt, this message translates to:
  /// **'Perfil updated com sucesso!'**
  String get perfilAtualizadoSucesso;

  /// No description provided for @nome.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get nome;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @telefone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get telefone;

  /// No description provided for @porFavorInsira.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira'**
  String get porFavorInsira;

  /// No description provided for @estatisticasTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get estatisticasTitulo;

  /// No description provided for @galeriaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Galeria de Badges'**
  String get galeriaTitulo;

  /// No description provided for @pesquisar.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar...'**
  String get pesquisar;

  /// No description provided for @total.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @ativo.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get ativo;

  /// No description provided for @obtido.
  ///
  /// In pt, this message translates to:
  /// **'Obtido'**
  String get obtido;

  /// No description provided for @validade.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get validade;

  /// No description provided for @avisoExpiradoParte1.
  ///
  /// In pt, this message translates to:
  /// **'Este Badge expirou em '**
  String get avisoExpiradoParte1;

  /// No description provided for @avisoExpiradoParte2.
  ///
  /// In pt, this message translates to:
  /// **'. Para manteres as tuas competências atualizadas, é necessário renovar o badge.'**
  String get avisoExpiradoParte2;

  /// No description provided for @semBadgesSeccao.
  ///
  /// In pt, this message translates to:
  /// **'Sem badges nesta secção.'**
  String get semBadgesSeccao;

  /// No description provided for @filtrar.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get filtrar;

  /// No description provided for @ordenarPor.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get ordenarPor;

  /// No description provided for @ordenarNomeAsc.
  ///
  /// In pt, this message translates to:
  /// **'Nome (A-Z)'**
  String get ordenarNomeAsc;

  /// No description provided for @ordenarNomeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Nome (Z-A)'**
  String get ordenarNomeDesc;

  /// No description provided for @ordenarPontosAsc.
  ///
  /// In pt, this message translates to:
  /// **'Pontos (Menor)'**
  String get ordenarPontosAsc;

  /// No description provided for @ordenarPontosDesc.
  ///
  /// In pt, this message translates to:
  /// **'Pontos (Maior)'**
  String get ordenarPontosDesc;

  /// No description provided for @nivel.
  ///
  /// In pt, this message translates to:
  /// **'Nível'**
  String get nivel;

  /// No description provided for @tipo.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get tipo;

  /// No description provided for @confirmar.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirmar;

  /// No description provided for @cancelar.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @basico.
  ///
  /// In pt, this message translates to:
  /// **'Básico'**
  String get basico;

  /// No description provided for @intermedio.
  ///
  /// In pt, this message translates to:
  /// **'Intermédio'**
  String get intermedio;

  /// No description provided for @senior.
  ///
  /// In pt, this message translates to:
  /// **'Sénior'**
  String get senior;

  /// No description provided for @especialista.
  ///
  /// In pt, this message translates to:
  /// **'Especialista'**
  String get especialista;

  /// No description provided for @lider.
  ///
  /// In pt, this message translates to:
  /// **'Líder'**
  String get lider;

  /// No description provided for @serviceLineLabel.
  ///
  /// In pt, this message translates to:
  /// **'Service Line'**
  String get serviceLineLabel;

  /// No description provided for @areaLabel.
  ///
  /// In pt, this message translates to:
  /// **'Área'**
  String get areaLabel;

  /// No description provided for @cloudServices.
  ///
  /// In pt, this message translates to:
  /// **'Cloud Services'**
  String get cloudServices;

  /// No description provided for @appDev.
  ///
  /// In pt, this message translates to:
  /// **'Application Development'**
  String get appDev;

  /// No description provided for @enterpriseSolutions.
  ///
  /// In pt, this message translates to:
  /// **'Enterprise Solutions'**
  String get enterpriseSolutions;

  /// No description provided for @securityServices.
  ///
  /// In pt, this message translates to:
  /// **'Security Services'**
  String get securityServices;

  /// No description provided for @learningPathLabel.
  ///
  /// In pt, this message translates to:
  /// **'Learning Path'**
  String get learningPathLabel;

  /// No description provided for @digitalInnovation.
  ///
  /// In pt, this message translates to:
  /// **'Digital Innovation'**
  String get digitalInnovation;

  /// No description provided for @cloudSolutions.
  ///
  /// In pt, this message translates to:
  /// **'Cloud Solutions'**
  String get cloudSolutions;

  /// No description provided for @lowCodeDev.
  ///
  /// In pt, this message translates to:
  /// **'Low Code Development'**
  String get lowCodeDev;

  /// No description provided for @cyberSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Cyber Security'**
  String get cyberSecurity;

  /// No description provided for @devOpsAgile.
  ///
  /// In pt, this message translates to:
  /// **'DevOps & Agile'**
  String get devOpsAgile;

  /// No description provided for @novoObjetivo.
  ///
  /// In pt, this message translates to:
  /// **'Novo Objetivo'**
  String get novoObjetivo;

  /// No description provided for @classificacaoGeralTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Classificação Geral'**
  String get classificacaoGeralTitulo;

  /// No description provided for @totalBadgesKpi.
  ///
  /// In pt, this message translates to:
  /// **'Total de Badges'**
  String get totalBadgesKpi;

  /// No description provided for @lugarGeralKpi.
  ///
  /// In pt, this message translates to:
  /// **'Lugar geral'**
  String get lugarGeralKpi;

  /// No description provided for @lugarGeralValorKpi.
  ///
  /// In pt, this message translates to:
  /// **'4.º'**
  String get lugarGeralValorKpi;

  /// No description provided for @mediaProgressoKpi.
  ///
  /// In pt, this message translates to:
  /// **'Média de Progresso'**
  String get mediaProgressoKpi;

  /// No description provided for @objetivosAtivosKpi.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos Ativos'**
  String get objetivosAtivosKpi;

  /// No description provided for @periodoSemanaAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Sem'**
  String get periodoSemanaAbbr;

  /// No description provided for @periodoMesAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get periodoMesAbbr;

  /// No description provided for @periodoTrimestreAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Trim'**
  String get periodoTrimestreAbbr;

  /// No description provided for @periodoAnoAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get periodoAnoAbbr;

  /// No description provided for @periodoSemana.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get periodoSemana;

  /// No description provided for @periodoMes.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get periodoMes;

  /// No description provided for @periodoAno.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get periodoAno;

  /// No description provided for @periodoSempre.
  ///
  /// In pt, this message translates to:
  /// **'Sempre'**
  String get periodoSempre;

  /// No description provided for @filtroArea.
  ///
  /// In pt, this message translates to:
  /// **'Área'**
  String get filtroArea;

  /// No description provided for @filtroServiceLine.
  ///
  /// In pt, this message translates to:
  /// **'Service Line'**
  String get filtroServiceLine;

  /// No description provided for @filtroFuncao.
  ///
  /// In pt, this message translates to:
  /// **'Função'**
  String get filtroFuncao;

  /// No description provided for @filtrarPor.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por'**
  String get filtrarPor;

  /// No description provided for @nenhumUtilizadorEncontrado.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum utilizador encontrado para este filtro.'**
  String get nenhumUtilizadorEncontrado;

  /// No description provided for @semanaLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sem'**
  String get semanaLabel;

  /// No description provided for @mesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get mesLabel;

  /// No description provided for @segundaAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Seg'**
  String get segundaAbbr;

  /// No description provided for @tercaAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Ter'**
  String get tercaAbbr;

  /// No description provided for @quartaAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Qua'**
  String get quartaAbbr;

  /// No description provided for @quintaAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Qui'**
  String get quintaAbbr;

  /// No description provided for @sextaAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Sex'**
  String get sextaAbbr;

  /// No description provided for @sabadoAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Sáb'**
  String get sabadoAbbr;

  /// No description provided for @domingoAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Dom'**
  String get domingoAbbr;

  /// No description provided for @janeiroAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Jan'**
  String get janeiroAbbr;

  /// No description provided for @fevereiroAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Fev'**
  String get fevereiroAbbr;

  /// No description provided for @marcoAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Mar'**
  String get marcoAbbr;

  /// No description provided for @abrilAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Abr'**
  String get abrilAbbr;

  /// No description provided for @maioAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Mai'**
  String get maioAbbr;

  /// No description provided for @junhoAbbr.
  ///
  /// In pt, this message translates to:
  /// **'Jun'**
  String get junhoAbbr;

  /// No description provided for @dataLimite.
  ///
  /// In pt, this message translates to:
  /// **'Data Limite'**
  String get dataLimite;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es', 'en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
