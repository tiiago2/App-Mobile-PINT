class DatabaseSchema {
  // --- Nome das Tabelas ---
  static const String perfilTable = 'perfil';
  static const String badgesTable = 'badges';
  static const String requisitosTable = 'requisitos';
  static const String badgesRequisitosTable = 'badges_requisitos';
  static const String submissoesTable = 'submissoes';
  static const String documentosSubmissaoTable = 'documentos_submissao';
  static const String historicoTable = 'historico_candidatura';
  static const String objetivosTable = 'objetivos';
  static const String assinaturaTable = 'assinaturas';
  static const String badgesAssinaturaTable = 'badges_assinatura';
  static const String notificacoesTable = 'notificacoes';
  static const String registoBadgesTable = 'registo_badges';
  static const String areasTable = 'areas';
  static const String serviceLinesTable = 'service_lines';
  static const String outrosUsersTable = 'outros_users';
  static const String learningPathsTable = 'learning_paths';
  static const String niveisTable = 'niveis';
  static const String permissoesTable = 'permissoes';
  static const String submissaoRequisitosTable = 'submissao_requisitos';
  static const String syncStateTable = 'sync_state';
  static const String syncOutboxTable = 'sync_outbox';

  // --- Ativação Obrigatória de Chaves Estrangeiras ---
  static const String enableForeignKeys = 'PRAGMA foreign_keys = ON;';

  // --- Scripts de Criação de Tabelas ---

  static const String createSyncStateTable = '''
    CREATE TABLE IF NOT EXISTS $syncStateTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      entity TEXT NOT NULL,
      last_sync_at TEXT,
      cursor TEXT,
      UNIQUE (user_id, entity)
    )
  ''';

  static const String createSyncOutboxTable = '''
    CREATE TABLE IF NOT EXISTS $syncOutboxTable (
      id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL,
      entity TEXT NOT NULL,
      operation TEXT NOT NULL,
      local_record_id INTEGER,
      client_id TEXT,
      payload TEXT,
      created_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      attempts INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String createPerfilTable = '''
    CREATE TABLE IF NOT EXISTS $perfilTable (
      id_utilizador INTEGER PRIMARY KEY,
      nome_user TEXT NOT NULL,
      email TEXT NOT NULL,
      telefone TEXT,
      imagem_perfil TEXT,
      id_area TEXT,
      last_login TEXT,
      profile_json TEXT NOT NULL,
      local_updated_at TEXT NOT NULL,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'pending_insert'
    )
  ''';

  static const String createBadgesTable = '''
    CREATE TABLE IF NOT EXISTS $badgesTable (
      id_badge INTEGER PRIMARY KEY,
      nome_badge TEXT NOT NULL,
      descricao_badge TEXT,
      imagem TEXT,
      especial INTEGER NOT NULL DEFAULT 0,
      pontos_badge INTEGER,
      validade INTEGER,
      id_area INTEGER,
      id_nivel INTEGER,
      badge_json TEXT NOT NULL,
      update_badge TEXT,
      deleted_badge INT,
      cached_at TEXT NOT NULL
    )
  ''';

  static const String createRequisitosTable = '''
    CREATE TABLE IF NOT EXISTS $requisitosTable (
      id_requisito INTEGER PRIMARY KEY,
      nome_requisito TEXT NOT NULL,
      descricao_requisito TEXT NOT NULL,
      requisito_json TEXT,
      update_requisito TEXT,
      deleted_requisito INT
    )
  ''';

  static const String createBadgesRequisitosTable = '''
    CREATE TABLE IF NOT EXISTS $badgesRequisitosTable (
      id_requisito INTEGER NOT NULL,
      id_badge INTEGER NOT NULL,
      PRIMARY KEY (id_requisito, id_badge),
      FOREIGN KEY (id_requisito) REFERENCES $requisitosTable(id_requisito) ON DELETE CASCADE,
      FOREIGN KEY (id_badge) REFERENCES $badgesTable(id_badge) ON DELETE CASCADE
    )
  ''';

  static const String createSubmissoesTable = '''
    CREATE TABLE IF NOT EXISTS $submissoesTable (
      id_submissao_local INTEGER PRIMARY KEY AUTOINCREMENT,
      id_submissao INTEGER UNIQUE,
      id_utilizador INTEGER NOT NULL,
      id_badge INTEGER NOT NULL,
      status TEXT NOT NULL,
      remote_status TEXT,
      data_criacao TEXT NOT NULL,
      data_submissao TEXT,
      submissao_json TEXT,
      local_updated_at TEXT NOT NULL,
      updated_submissao TEXT,
      sync_status TEXT NOT NULL DEFAULT 'pending_insert',
      deleted_submissao TEXT,
      FOREIGN KEY (id_badge) REFERENCES $badgesTable(id_badge)
    )
  ''';

  static const String createDocumentosTable = '''
    CREATE TABLE IF NOT EXISTS $documentosSubmissaoTable (
      id_ficheiro_local INTEGER PRIMARY KEY AUTOINCREMENT,
      id_submissao_local INTEGER NOT NULL,
      id_submissao INTEGER,
      id_requisito INTEGER NOT NULL,
      id_ficheiro INTEGER,
      ficheiro TEXT,
      ficheiro_local TEXT,
      url_ficheiro TEXT,
      tamanho_bytes INTEGER,
      hash_ficheiro TEXT,
      upload_status TEXT,
      upload_error TEXT,
      updated_file TEXT,
      created_local_at TEXT,
      synced_at TEXT,
      sync_status TEXT DEFAULT 'pending',
      deleted_file INTEGER DEFAULT 0,
      FOREIGN KEY (id_submissao_local) REFERENCES $submissoesTable(id_submissao_local) ON DELETE CASCADE
    )
  ''';

  static const String createHistoricoTable = '''
    CREATE TABLE IF NOT EXISTS $historicoTable (
      id_historico INTEGER PRIMARY KEY,
      id_utilizador INTEGER,
      id_submissao INTEGER NOT NULL,
      aceite INT NOT NULL,
      data_avaliacao TEXT NOT NULL,
      feedback TEXT,
      historico_json TEXT,
      updated_historico TEXT,
      deleted_historico INT,
      FOREIGN KEY (id_submissao) REFERENCES $submissoesTable(id_submissao) ON DELETE CASCADE
    )
  ''';

  static const String createObjetivosTable = '''
    CREATE TABLE IF NOT EXISTS $objetivosTable (
      id_objetivo_local INTEGER PRIMARY KEY AUTOINCREMENT,
      id_objetivo INTEGER,
      id_utilizador INTEGER NOT NULL,
      id_badge INTEGER NOT NULL,
      data_inicial TEXT NOT NULL,
      data_final TEXT NOT NULL,
      data_conclusao TEXT,
      badge_json TEXT,
      deleted_objetivo INT,
      local_updated_at TEXT NOT NULL,
      updated_objetivo TEXT,
      sync_status TEXT NOT NULL DEFAULT 'pending_insert',
      FOREIGN KEY (id_badge) REFERENCES $badgesTable(id_badge)
    )
  ''';

  static const String createAssinaturaTable = '''
    CREATE TABLE IF NOT EXISTS $assinaturaTable (
      id_assinatura_local INTEGER PRIMARY KEY AUTOINCREMENT,
      id_assinatura INTEGER,
      id_proprietario INTEGER NOT NULL UNIQUE,
      assinatura_json TEXT,
      update_assinatura TEXT,
      local_updated_at TEXT NOT NULL,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'pending_insert'
    )
  ''';

  static const String createBadgesAssinaturaTable = '''
    CREATE TABLE IF NOT EXISTS $badgesAssinaturaTable (
      id_assinatura_local INTEGER NOT NULL,
      id_badge INTEGER NOT NULL,
      PRIMARY KEY (id_assinatura_local, id_badge),
      FOREIGN KEY (id_assinatura_local) REFERENCES $assinaturaTable(id_assinatura_local) ON DELETE CASCADE,
      FOREIGN KEY (id_badge) REFERENCES $badgesTable(id_badge)
    )
  ''';

  static const String createNotificacoesTable = '''
    CREATE TABLE IF NOT EXISTS $notificacoesTable (
      id_utilizador INTEGER NOT NULL,
      id_notificacao INTEGER NOT NULL,
      descricao_notificacao TEXT NOT NULL,
      tipo_notificacao TEXT NOT NULL,
      data_envio TEXT,
      lida INT NOT NULL,
      last_read TEXT,
      notificacao_json TEXT,
      updated_notificacao TEXT,
      deleted_notificacao INT,
      PRIMARY KEY (id_utilizador, id_notificacao )
    )
  ''';

  static const String createRegistoBadgesTable = '''
    CREATE TABLE IF NOT EXISTS $registoBadgesTable (
      id_utilizador INTEGER NOT NULL,
      id_registo INTEGER NOT NULL,
      id_badge INTEGER NOT NULL,
      data_obtencao TEXT NOT NULL,
      expirado INT,
      registo_json TEXT,
      updated_registo TEXT,
      deleted_registo INT,
      PRIMARY KEY (id_utilizador, id_registo),
      FOREIGN KEY (id_badge) REFERENCES $badgesTable(id_badge)
    )
  ''';

  static const String createAreasTable = '''
    CREATE TABLE IF NOT EXISTS $areasTable (
      id_area INTEGER PRIMARY KEY,
      id_service_line INTEGER,
      nome_area TEXT NOT NULL,
      updated_area TEXT,
      deleted_area INT
    )
  ''';

  static const String createServiceLinesTable = '''
    CREATE TABLE IF NOT EXISTS $serviceLinesTable (
      id_service_line INTEGER PRIMARY KEY,
      nome_service_line TEXT NOT NULL,
      id_learning_path INTEGER,
      updated_service TEXT,
      deleted_service INT
    )
  ''';

  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS $outrosUsersTable (
      id_utilizador INTEGER PRIMARY KEY,
      nome_user TEXT,
      id_area INTEGER,
      imagem_perfil TEXT,
      update_user TEXT,
      pontos_semana INTEGER DEFAULT 0,
      pontos_mes INTEGER DEFAULT 0,
      pontos_ano INTEGER DEFAULT 0,
      pontos_totais INTEGER DEFAULT 0,
      ativo INTEGER DEFAULT 1,
      FOREIGN KEY (id_area) REFERENCES $areasTable(id_area) ON DELETE SET NULL
    )
  ''';

  static const String createLearningPathsTable = '''
    CREATE TABLE IF NOT EXISTS $learningPathsTable (
      id_learning_path INTEGER PRIMARY KEY,
      nome_learning_path TEXT NOT NULL,
      descricao_larning_path TEXT,
      updated_path TEXT,
      deleted_path INT
    )
  ''';

  static const String createNiveisTable = '''
    CREATE TABLE IF NOT EXISTS $niveisTable (
      id_nivel INTEGER PRIMARY KEY,
      nome_nivel TEXT NOT NULL,
      updated_nivel TEXT,
      deleted_nivel INT
    )
  ''';

  static const String createPermissoesTable = '''
    CREATE TABLE IF NOT EXISTS $permissoesTable (
      id_permissao INTEGER PRIMARY KEY,
      descricao_permissao TEXT,
      toggle INT NOT NULL,
      scope_json TEXT,
      updated_permissao TEXT,
      deleted_permissao INT
    )
  ''';

  static const String createSubmissaoRequisitosTable = '''
    CREATE TABLE IF NOT EXISTS $submissaoRequisitosTable (
      id_submissao_local INTEGER NOT NULL,
      id_requisito INTEGER NOT NULL,
      estado_local TEXT NOT NULL DEFAULT 'pending',
      estado_remoto TEXT,
      local_updated_at TEXT NOT NULL,
      server_updated_at TEXT,
      deleted_at TEXT,
      PRIMARY KEY (id_submissao_local, id_requisito),
      FOREIGN KEY (id_submissao_local)
        REFERENCES $submissoesTable(id_submissao_local) ON DELETE CASCADE,
      FOREIGN KEY (id_requisito)
        REFERENCES $requisitosTable(id_requisito)
    )
  ''';

  // --- Índices para Performance e Sincronização ---

  static const List<String> createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_outbox_status ON $syncOutboxTable (status);',
    'CREATE INDEX IF NOT EXISTS idx_submissoes_sync ON $submissoesTable (sync_status);',
    'CREATE INDEX IF NOT EXISTS idx_submissoes_remote ON $submissoesTable (id_submissao);',
    'CREATE INDEX IF NOT EXISTS idx_docs_submissao ON $documentosSubmissaoTable (id_submissao_local);',
    'CREATE INDEX IF NOT EXISTS idx_docs_sync_status ON $documentosSubmissaoTable (sync_status);',
    'CREATE INDEX IF NOT EXISTS idx_objetivos_sync ON $objetivosTable (sync_status);',
    'CREATE INDEX IF NOT EXISTS idx_historico_submissao ON $historicoTable (id_submissao);',
    'CREATE INDEX IF NOT EXISTS idx_notificacoes_user ON $notificacoesTable (id_utilizador);',
  ];
}